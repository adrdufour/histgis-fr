-- ============================================================================
-- histgis — 136_trous_aisne_alpes_aube_aude.sql : trous signalés par Adrien le
--           26 octobre 2026
--
--   cd ~/Téléchargements/projet_carte
--   psql -d histgis -f sql/136_trous_aisne_alpes_aube_aude.sql                -- à blanc
--   psql -d histgis -1 -v appliquer=1 -f sql/136_trous_aisne_alpes_aube_aude.sql
--   psql -d histgis -1 -v defaire=1 -f sql/136_trous_aisne_alpes_aube_aude.sql
--
-- Signalés sur la carte : sans circonscription Harly (1976-1987), Lettret
-- (1971, 1985), Torvilliers et les cantons de Troyes (1975-1987) ; sans
-- canton Fontaine-les-Grès (1987), Mas-des-Cours (1953), Castelnaudary,
-- Portel-des-Corbières et Laprade (1988). Tous figurent dans `p120_reste` :
-- ce sont des trous que `120` a vus et laissés, faute de règle. Ici chacun est
-- relu dans sa source. La circonscription suit, comme dans `134`, celle du
-- canton de 1958 jusqu'au 1986-11-24 (règle de `113`) ; le trou de
-- circonscription n'était que l'ombre du trou cantonal.
--
-- 1. AISNE, Harly (02371), 1955-1973. Saint-Quentin au jalon de 1954,
--    Saint-Quentin-Sud dès 1973 : décrets n° 73-712 et 73-826, qui la nomment
--    TOUS DEUX dans Saint-Quentin-Sud (`jorf_txt/JORF_19730819_192_raw.txt`,
--    l. 1600). Verdict `plusieurs_actes` : la règle B de `120` n'admet qu'un
--    acte. Aucun autre acte de l'Aisne entre 1955 et 1973. Bout gauche.
--    Circonscription : liste départementale, puis la 2e (Saint-Quentin, 1958).
--
-- 2. HAUTES-ALPES, Lettret (05074), 1941-1982. Tallard en 1870 et dès 1982 ;
--    entre les deux, le jalon de 1968 la lisait au canton « 28 », hors bornes
--    du département, avec Tallard (23) pour autre lecture
--    (`cog1968/communes_1968_fusion.csv` : `canton_conteste`, `hors_borne`).
--    La base en avait fait Gap-Nord-Ouest (0528), canton de 1982. Le décret
--    de 1973 qui divise Gap (`jorf_txt/JORF_19730717_164_col.txt`, l. 875 et
--    suiv.) ne nomme pas Lettret, celui de 1982 non plus (Gap seul). Les deux
--    rattachements à 0528 de 1968-1973 sont RETIRÉS (gardés dans la trace) et
--    Tallard posé de 1941 à 1982. Circonscription : liste, puis la 1re.
--
-- 3. AUBE.
--    Torvilliers (10381), 1955-1973 : Troyes-2 au jalon de 1954, Sainte-Savine
--      par le décret n° 73-652, qui la nomme (`JORF_19730717_164_raw.txt`,
--      l. 796-798) — la lecture l'avait perdue en fin de ligne (« et de
--      Torvilliers »). Bout gauche ; circonscription : liste, puis la 3e
--      (Troyes-2, 1958).
--    Fontaine-les-Grès (10151), 1985-1988 : décret n° 85-71 du 22 janvier
--      1985, art. 2 (`JORF_19850123_19_raw.txt`, l. 2989) : « détachée du
--      canton de Romilly-sur-Seine-I et rattachée au canton de Méry-sur-Seine »,
--      effet aux cantonales du 1985-03-10. La base ne la mettait à Méry qu'en
--      1988. Circonscription : la 3e jusqu'en 1986.
--    Les cantons de Troyes créés en 1973 (4e à 7e, fractions #1029 à #1032)
--      n'avaient aucune circonscription jusqu'en 1986 : `113` donne à un atome
--      celle de son canton de 1958, et ils n'en avaient pas. Ils sont rangés
--      par leur SOL : chaque fraction de 1973 tombe à 100 % dans un seul
--      canton d'avant 1973 (`carte_coupe_ville('10387', …)` en 1960 et 1980,
--      lignes de `cartes/coupes_ville.csv`) :
--         1973      → avant 1973 → circonscription de 1958
--         Troyes-1  → Troyes-1   → 1re          Troyes-4 → Troyes-2 → 3e
--         Troyes-2  → Troyes-1   → 1re          Troyes-5, -6, -7 → Troyes-3 → 2e
--         Troyes-3  → Troyes-2   → 3e
--      C'est exactement le rangement de 1986 (`circo/partition_ville.csv`).
--      Or la même règle de `113` gardait aux fractions #1023 et #1024 la
--      circonscription de leur canton de 1958 jusqu'en 1986, alors que leur
--      sol change en 1973 : Troyes-2 passait de la 3e à la 1re, Troyes-3 de
--      la 2e à la 3e. Ces deux rattachements de `113` sont COUPÉS au
--      1973-09-23 (ancienne borne dans la trace) et prolongés par le bon.
--
-- 4. AUDE. Aucun acte de 1973 à 1998 ne touche Castelnaudary, Sigean ni
--    Mas-Cabardès : 1973 (Carcassonne, Narbonne), décret du 22 janvier 1985
--    (Narbonne, Carcassonne), 26 février 1997 (Carcassonne-II-Sud), relus
--    dans `JORF_19730717_164_col.txt`, `JORF_19850123_19_raw.txt` (l. 3007),
--    `JORF_19970227_49_col.txt` (l. 2284).
--    Castelnaudary-Nord et -Sud (fractions #1109, #1110), 1973-1998 : même
--      canton aux deux bouts ; `120` ne traite pas les fractions.
--    Portel-des-Corbières (11295), 1973-1998 : Sigean aux deux bouts.
--      Verdict `accord_nomme` de `120` par ERREUR D'APPARIEMENT : les décrets
--      n° 82-35 (Outreau) et 91-217 (canton de Portel), qui nomment « Portel »
--      — Le Portel, Pas-de-Calais (62667) —, ont été rapportés à la commune
--      de l'Aude par le repli « autre departement » de
--      `cantons/composition_jo.py` (GEOFLA écrit « LE PORTEL »).
--    Laprade (11189), 1973-1993 : décret du 25 janvier 1993
--      (`JORF_19930127_22_col.txt`, l. 976) : « rattachée au canton de
--      Saissac », depuis Mas-Cabardès ; la base pose Saissac dès le
--      1993-01-26. Mas-Cabardès jusque-là.
--    Mas-des-Cours (11223), 1953 : table analytique du JO de 1953, p. 1749,
--      « Commune de Mas-des-Cours au canton de Carcassonne-Est »
--      (`cantons/transferts_tables_jo.csv`) ; la base arrêtait Capendu au
--      1953-02-22 et ne reprenait Carcassonne-Est qu'au jalon de 1954.
--    Circonscriptions de 1958 jusqu'en 1986 : Castelnaudary 3e, Sigean 2e,
--      Mas-Cabardès 1re — celles que ces atomes avaient jusqu'en 1973.
--
-- Réversible : `p136_trace`. Rejouable. Après `134` (même nature).
-- Il retire deux lignes du jalon de 1968 (`59`/`81`) et coupe deux lignes de
-- `113` : rejouer l'un de ceux-là demande de défaire celui-ci d'abord.
-- ============================================================================
\set ON_ERROR_STOP on
SET search_path TO histgis, public;

CREATE TABLE IF NOT EXISTS p136_trace (
    quoi text NOT NULL, cle text NOT NULL,
    atom_id text, unit_id text, niveau text,
    ancien_from date, ancien_to date,
    pose_le timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (quoi, cle)
);

\if :{?defaire}
\set retirer 1
\endif
\if :{?appliquer}
\set retirer 1
\endif

\if :{?retirer}
DELETE FROM membership m
 WHERE EXISTS (SELECT 1 FROM p136_trace t
                WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text);
-- bornes rendues, lignes retirées remises
UPDATE membership m SET valid_to = t.ancien_to
  FROM p136_trace t WHERE t.quoi = 'coupe' AND t.cle = m.membership_id::text;
INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
SELECT atom_id, unit_id, niveau, ancien_from, ancien_to
  FROM p136_trace WHERE quoi = 'retire';
DELETE FROM p136_trace;
\endif

\if :{?defaire}
\echo ''
\echo '=== Trace retirée. ==='
\else

-- Lignes à retirer (jalon de 1968 mal lu) et à couper (`113`, Troyes)
DROP TABLE IF EXISTS t136_retire;
CREATE TEMP TABLE t136_retire AS
SELECT membership_id, atom_id, unit_id, niveau, valid_from, valid_to
  FROM membership
 WHERE atom_id = '19331' AND niveau = 'canton' AND unit_id = '0528'
   AND valid_to <= '1973-09-23';

DROP TABLE IF EXISTS t136_coupe;
CREATE TEMP TABLE t136_coupe AS
SELECT membership_id, atom_id, unit_id, valid_to
  FROM membership
 WHERE niveau = 'circo' AND valid_from = '1958-01-01' AND valid_to = '1986-11-24'
   AND (atom_id, unit_id) IN (('38334#1023', '10-03@1958'), ('38334#1024', '10-02@1958'));

DROP TABLE IF EXISTS t136_lu;
CREATE TEMP TABLE t136_lu (atom_id text, niveau text, unit_id text, du date, au date, fonde text);
INSERT INTO t136_lu VALUES
-- 1. Aisne
('16690','canton','0228','1955-01-01','1973-09-23','Harly : Saint-Quentin (bout gauche) ; 73-712, 73-826'),
('16690','circo','L0201@1945','1955-01-01','1958-01-01','liste départementale'),
('16690','circo','02-02@1958','1958-01-01','1986-11-24','1958 : canton de Saint-Quentin'),
-- 2. Hautes-Alpes
('19331','canton','0523','1941-01-01','1982-03-14','Lettret : Tallard ; jalon de 1968 contesté, hors bornes'),
('19331','circo','L0501@1945','1945-01-01','1958-01-01','liste départementale'),
('19331','circo','05-01@1958','1958-01-01','1986-11-24','1958 : canton de Tallard'),
-- 3. Aube
('37780','canton','1023','1955-01-01','1973-09-23','Torvilliers : Troyes-2 (bout gauche) ; 73-652'),
('37780','circo','L1001@1945','1955-01-01','1958-01-01','liste départementale'),
('37780','circo','10-03@1958','1958-01-01','1986-11-24','1958 : canton de Troyes-2'),
('14213','canton','1014','1985-03-10','1988-09-25','Fontaine-les-Grès : 85-71 art. 2, Méry-sur-Seine'),
('14213','circo','10-03@1958','1985-03-10','1986-11-24','1958 : canton de Romilly-sur-Seine'),
('38334#1023','circo','10-01@1958','1973-09-23','1986-11-24','Troyes-2 de 1973, sol de Troyes-1 d''avant'),
('38334#1024','circo','10-03@1958','1973-09-23','1986-11-24','Troyes-3 de 1973, sol de Troyes-2 d''avant'),
('38334#1029','circo','10-03@1958','1973-09-23','1986-11-24','Troyes-4 de 1973, sol de Troyes-2 d''avant'),
('38334#1030','circo','10-02@1958','1973-09-23','1986-11-24','Troyes-5 de 1973, sol de Troyes-3 d''avant'),
('38334#1031','circo','10-02@1958','1973-09-23','1986-11-24','Troyes-6 de 1973, sol de Troyes-3 d''avant'),
('38334#1032','circo','10-02@1958','1973-09-23','1986-11-24','Troyes-7 de 1973, sol de Troyes-3 d''avant'),
-- 4. Aude
('7123#1109','canton','1109','1973-09-23','1998-03-15','Castelnaudary-Nord aux deux bouts'),
('7123#1110','canton','1110','1973-09-23','1998-03-15','Castelnaudary-Sud aux deux bouts'),
('7123#1109','circo','11-03@1958','1973-09-23','1986-11-24','1958 : Castelnaudary-Nord'),
('7123#1110','circo','11-03@1958','1973-09-23','1986-11-24','1958 : Castelnaudary-Sud'),
('27661','canton','1130','1973-09-23','1998-03-15','Portel-des-Corbières : Sigean aux deux bouts'),
('27661','circo','11-02@1958','1973-09-23','1986-11-24','1958 : canton de Sigean'),
('27852','canton','1121','1973-09-23','1993-01-26','Laprade : Mas-Cabardès jusqu''au décret du 25 janvier 1993'),
('27852','circo','11-01@1958','1973-09-23','1986-11-24','1958 : canton de Mas-Cabardès'),
('21505','canton','1107','1953-02-22','1954-01-01','Mas-des-Cours : table analytique 1953, p. 1749');

\echo ''
\echo '=== 1. Retirés (attendu : 2, Lettret à Gap-Nord-Ouest 1968-1973) ==='
SELECT * FROM t136_retire ORDER BY valid_from;

\echo ''
\echo '=== 2. Coupés au 1973-09-23 (attendu : 2, Troyes-2 et -3) ==='
SELECT * FROM t136_coupe ORDER BY atom_id;

\echo ''
\echo '=== 3. À poser (attendu : 26 lignes, aucune collision) ==='
SELECT l.atom_id, l.niveau, l.unit_id, l.du, l.au,
       (SELECT string_agg(m.unit_id||' '||m.valid_from||'→'||m.valid_to, ', ')
          FROM membership m WHERE m.atom_id = l.atom_id AND m.niveau = l.niveau
           AND m.periode && daterange(l.du, l.au, '[)')
           AND m.membership_id NOT IN (SELECT membership_id FROM t136_retire)
           AND NOT (m.membership_id IN (SELECT membership_id FROM t136_coupe)
                    AND l.du >= '1973-09-23')) AS collision
  FROM t136_lu l ORDER BY 1, 2, 4;

\if :{?appliquer}
DO $$
BEGIN
    IF (SELECT count(*) FROM t136_retire) <> 2 OR (SELECT count(*) FROM t136_coupe) <> 2 THEN
        RAISE EXCEPTION 'La base a bougé : lignes à retirer ou à couper introuvables (recettes 1-2).';
    END IF;
END $$;

INSERT INTO p136_trace (quoi, cle, atom_id, unit_id, niveau, ancien_from, ancien_to)
SELECT 'retire', membership_id::text, atom_id, unit_id, niveau, valid_from, valid_to
  FROM t136_retire;
DELETE FROM membership WHERE membership_id IN (SELECT membership_id FROM t136_retire);

INSERT INTO p136_trace (quoi, cle, atom_id, unit_id, niveau, ancien_to)
SELECT 'coupe', membership_id::text, atom_id, unit_id, 'circo', valid_to FROM t136_coupe;
UPDATE membership SET valid_to = '1973-09-23'
 WHERE membership_id IN (SELECT membership_id FROM t136_coupe);

WITH ins AS (
  INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
  SELECT atom_id, unit_id, niveau, du, au FROM t136_lu l
  -- au rejeu, `123` a déjà posé les 4e à 7e cantons de Troyes
  -- (`circo/partition_ville.csv`, état « 136 ») : même unité, rien à faire
   WHERE NOT EXISTS (SELECT 1 FROM membership m
                      WHERE m.atom_id = l.atom_id AND m.niveau = l.niveau
                        AND m.unit_id = l.unit_id
                        AND m.periode @> daterange(l.du, l.au, '[)'))
  RETURNING membership_id)
INSERT INTO p136_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '=== Posé ==='
SELECT quoi, count(*) FROM p136_trace GROUP BY 1 ORDER BY 1;
\endif
\endif
