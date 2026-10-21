-- ============================================================================
-- histgis — 121_ain_cessions_trous.sql : les communes de l'Ain que la carte
-- perdait entre 1955 et 1998
--
--   ESSAI (défaut) :  psql -d histgis -f sql/121_ain_cessions_trous.sql
--   CORRECTION     :  psql -d histgis -v poser=on -f sql/121_ain_cessions_trous.sql
--   DÉFAIRE SEUL   :  psql -d histgis -v defaire=on -f sql/121_ain_cessions_trous.sql
--
-- À jouer EN DERNIER, après 120. Une seule transaction : sans `-v poser=on`,
-- tout est calculé, affiché, puis ROLLBACK ; avec, COMMIT.
--
-- POURQUOI
-- ========
-- La carte ne dessine une commune que si elle a, à la date, un canton OU une
-- circonscription du département. Signalé par Adrien le 21 octobre 2026
-- (Belmont-Luthézieu sans canton en 1990) : dans l'Ain, une vingtaine d'atomes sortaient
-- de la carte en 1955 ou en 1973 et n'y revenaient qu'en 1968, 1985, 1986 ou
-- 1998. Trois causes.
--
--   A. LA CESSION AU RHÔNE. Loi n° 67-1205 du 29 décembre 1967 (JO du 30,
--      p. 12980), effet au 1967-12-31 (COG, mouvement 41 ; règle C).
--      Rillieux, Crépieux-la-Pape, Sathonay-Camp et Sathonay-Village
--      n'avaient plus de canton de 1955 à 1985 : le jalon de 1954 les met à
--      Montluel et Trévoux, le jalon de 1968 du Rhône ne les porte pas, et
--      le canton de Rillieux (6939) ne remontait que jusqu'au plancher de
--      `79` (1985-03-10). Posé : l'ancien canton de l'Ain jusqu'à la
--      cession, le canton de Rillieux ensuite (Crépieux jusqu'à sa fusion
--      dans Rillieux-la-Pape, 1972-12-15, COG). Le DÉCRET qui crée le canton
--      de Rillieux n'est pas lu : la date de 1967 est celle de Wikipédia
--      (« Liste des cantons du Rhône »), qui range ces communes « au nouveau
--      canton de Rillieux » sous la loi de 1967.
--      Genay et Montanay ne sont PAS touchées : le décret du 12 avril 1969
--      (table analytique 1969, p. 3861, posé par `110`) les rattache au
--      canton de Neuville-sur-Saône, et la loi (art. 3) maintient les
--      conseillers généraux des « anciens cantons de Trévoux et de
--      Montluel ». Elles restent à Trévoux jusqu'en 1969.
--      NB : la loi ne cède au Rhône qu'une PORTION de Montanay (le reste va à
--      Mionnay) et des portions de Neyron et Miribel (à Rillieux). La trame
--      n'en dessine rien ; ce fichier non plus.
--
--   B. LE JALON DE 1968 MAL APPARIÉ. Trois lignes de l'Ain y portent un code
--      INSEE qui n'est pas le leur (`c68_src`, appariement psm4/psm6) :
--        01045 lu « Beynost » (Montluel)        → Birieux mise à Montluel
--        01138 lu « Cressin-Rochefort » (Belley) → Culoz mise à Belley
--        01451 lu « … Saint-Maurice-de-Rémens » (Chalamont) → Viriat
--              coupée en deux fractions, Bourg et Chalamont
--      1954 et 1999 s'accordant contre 1968, `97` laissait 1955-1967 vide.
--      Aucun acte cantonal dans l'Ain de 1955 à 1967 (registre `acte_effet`,
--      annexe VII) : le canton de 1954 vaut jusqu'à 1968, et au-delà tant
--      qu'aucun acte ne touche le canton.
--      Par la même absence d'acte, les communes absorbées entre 1955 et 1974
--      gardent leur canton de 1954 jusqu'à leur fusion (dates du COG) :
--      Forens, Lacoux, Longecombe, Proulieu, Vésenex-Crassy, Coupy,
--      Volognat, Charancin ; et Massieux, Parcieux, Sainte-Euphémie (absentes
--      du jalon de 1968, lignes hors borne) restent à Trévoux jusqu'à la
--      création de Reyrieux (n° 84-1222, effet 1985-03-10).
--
--   C. LE PLANCHER DE `79` EN 1998. Les actes de l'Ain après 1973 sont :
--      Bourg (1973, 1982, 1985), Oyonnax, Montluel, Miribel, Trévoux,
--      Péronnas, Viriat (1982, 1985), et quatre décrets de LIMITES lus sur
--      Légifrance le 21 octobre 2026, qui n'échangent que des parcelles :
--        12 juin 1990    Crozet → Sergy (Gex / Ferney-Voltaire)
--        9 sept. 1996    Viriat → Attignat (Viriat / Montrevel)
--        7 oct. 1996     Bellegarde ↔ Lancrans (Bellegarde / Collonges)
--        17 déc. 1996    Oyonnax ↔ Arbent (Oyonnax-Nord / Sud)
--      Aucun ne touche Villars, Seyssel, Nantua, Virieu-le-Grand ni
--      Champagne. Birieux (Villars), Culoz (Seyssel) et Béard-Géovreissiat
--      (Nantua) gardent donc leur canton de 1968 jusqu'au plancher de 1998.
--      BELMONT-LUTHÉZIEU : Belmont (Virieu-le-Grand) et Luthézieu (Champagne)
--      fusionnent le 1974-11-01 (fusion-association, COG), puis en fusion
--      simple le 1997-12-01. Le COG de 1999 met la commune à Champagne, et
--      aucun acte ne l'y a portée depuis : c'est donc la fusion de 1974 qui
--      l'a rattachée à Champagne. C'est une INFÉRENCE par absence d'acte (la
--      même que `79`), pas une lecture : l'arrêté de fusion n'est pas lu.
--      Même coupure au 1973-09-23 pour trois communes que la trame dessine
--      encore fin 1973 : Amareins et Cesseins (Saint-Trivier-sur-Moignans,
--      fusion au 1974-01-01) et Moëns (Ferney-Voltaire, 1975-01-01).
--
-- LES CIRCONSCRIPTIONS DE 1958
-- ============================
-- `113` pose la circonscription de 1958 d'après le canton : un atome sans
-- canton n'en recevait pas. Chaque canton de l'Ain est entier dans une seule
-- circonscription de 1958 (vérifié en 1962) ; ce fichier pose donc la
-- circonscription du canton sur les périodes qu'il remplit, de 1958 jusqu'à
-- la fin de la vie de l'atome dans l'Ain ou 1986-11-24. Rien n'est posé au
-- Rhône entre 1968 et 1986 : `113` n'y en pose pas non plus.
--
-- MÉCANIQUE
-- =========
-- `c121_cible` donne, par atome et par niveau, la suite exacte des périodes
-- voulues sur une FENÊTRE (de la première borne à la dernière, sans trou).
-- Une ligne sans unité vide la fenêtre (les deux fractions de Viriat). Les
-- périodes existantes entièrement dans la fenêtre sont retirées, celles qui
-- la chevauchent sont raccourcies ; une période qui la déborde des deux côtés
-- est coupée en deux.
--
-- TRACE ET RETOUR ARRIÈRE
-- =======================
-- `p121_trace` garde chaque période retirée (ligne entière, même
-- identifiant), chaque période raccourcie (bornes d'avant) et l'identifiant de
-- chaque insertion. Le § 1 rend à la base son état d'avant le passage
-- précédent : le fichier est rejouable seul.
-- ATTENTION : les périodes retirées viennent de `58`/`59` (jalon de 1968) et
-- de `113`. Pour rejouer l'un d'eux, ou `79`, `97`, `110`, `120` : défaire 121
-- d'abord (`-v defaire=on`), rejouer, puis 121.
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
CREATE TABLE IF NOT EXISTS p121_trace (
    quoi          text   NOT NULL CHECK (quoi IN ('insere', 'modifie', 'retire')),
    membership_id bigint NOT NULL,
    atom_id       text,
    unit_id       text,
    niveau        text,
    ancien_from   date,
    ancien_to     date,
    pose          timestamptz NOT NULL DEFAULT now()
);
DELETE FROM membership m USING p121_trace t
 WHERE t.quoi = 'insere' AND t.membership_id = m.membership_id;
UPDATE membership m SET valid_from = t.ancien_from, valid_to = t.ancien_to
  FROM p121_trace t
 WHERE t.quoi = 'modifie' AND t.membership_id = m.membership_id;
INSERT INTO membership (membership_id, atom_id, unit_id, niveau, valid_from, valid_to)
OVERRIDING SYSTEM VALUE
SELECT membership_id, atom_id, unit_id, niveau, ancien_from, ancien_to
  FROM p121_trace WHERE quoi = 'retire';
TRUNCATE p121_trace;

\if :defaire
\echo '== 121 DÉFAIT (COMMIT) : périodes rendues, insertions retirées.'
COMMIT;
\q
\endif

-- ---------------------------------------------------------------------------
-- 2. Ce qui doit être
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE c121_cible (
    atom_id    text NOT NULL,
    niveau     text NOT NULL,
    unit_id    text,               -- NULL : la fenêtre est vidée
    valid_from date NOT NULL,
    valid_to   date NOT NULL,
    motif      text NOT NULL
);

INSERT INTO c121_cible VALUES
-- A. cession au Rhône (loi du 29 décembre 1967, effet 1967-12-31)
('29181', 'canton', '0120',       '1955-01-01', '1967-12-31', 'A Rillieux : Montluel jusqu''à la cession'),
('29181', 'canton', '6939',       '1967-12-31', '1985-03-10', 'A Rillieux : canton de Rillieux (date Wikipédia)'),
('29181', 'circo',  '01-03@1958', '1958-01-01', '1967-12-31', 'A Rillieux : circo de Montluel'),
('11000', 'canton', '0120',       '1955-01-01', '1967-12-31', 'A Crépieux-la-Pape : Montluel jusqu''à la cession'),
('11000', 'canton', '6939',       '1967-12-31', '1972-12-15', 'A Crépieux-la-Pape : Rillieux jusqu''à la fusion'),
('11000', 'circo',  '01-03@1958', '1958-01-01', '1967-12-31', 'A Crépieux-la-Pape : circo de Montluel'),
('35434', 'canton', '0134',       '1955-01-01', '1967-12-31', 'A Sathonay-Camp : Trévoux jusqu''à la cession'),
('35434', 'canton', '6939',       '1967-12-31', '1985-03-10', 'A Sathonay-Camp : canton de Rillieux (date Wikipédia)'),
('35434', 'circo',  '01-03@1958', '1958-01-01', '1967-12-31', 'A Sathonay-Camp : circo de Trévoux'),
('35431', 'canton', '0134',       '1955-01-01', '1967-12-31', 'A Sathonay-Village : Trévoux jusqu''à la cession'),
('35431', 'canton', '6939',       '1967-12-31', '1985-03-10', 'A Sathonay-Village : canton de Rillieux (date Wikipédia)'),
('35431', 'circo',  '01-03@1958', '1958-01-01', '1967-12-31', 'A Sathonay-Village : circo de Trévoux'),
-- B. jalon de 1968 mal apparié, et communes absorbées
('4325',  'canton', '0135',       '1955-01-01', '1998-03-15', 'B Birieux : Villars (1968 lisait Beynost)'),
('4325',  'circo',  '01-03@1958', '1958-01-01', '1986-11-24', 'B Birieux : circo de Villars'),
('11340', 'canton', '0131',       '1955-01-01', '1998-03-15', 'B Culoz : Seyssel (1968 lisait Cressin-Rochefort)'),
('11340', 'circo',  '01-02@1958', '1958-01-01', '1986-11-24', 'B Culoz : circo de Seyssel'),
('40820', 'canton', '0105',       '1955-01-01', '1973-09-23', 'B Viriat : Bourg, entière'),
('40820', 'circo',  '01-01@1958', '1958-01-01', '1986-11-24', 'B Viriat : circo de Bourg'),
('40820#0105', 'canton', NULL,    '1968-01-01', '1973-09-23', 'B Viriat : fraction de 1968 retirée'),
('40820#0105', 'circo',  NULL,    '1968-01-01', '1973-09-23', 'B Viriat : fraction de 1968 retirée'),
('40820#0108', 'canton', NULL,    '1968-01-01', '1973-09-23', 'B Viriat : fraction lue sur Saint-Maurice-de-Rémens'),
('40820#0108', 'circo',  NULL,    '1968-01-01', '1973-09-23', 'B Viriat : fraction lue sur Saint-Maurice-de-Rémens'),
('21545', 'canton', '0134',       '1955-01-01', '1985-03-10', 'B Massieux : Trévoux jusqu''à Reyrieux'),
('21545', 'circo',  '01-03@1958', '1958-01-01', '1986-11-24', 'B Massieux : circo de Trévoux'),
('26161', 'canton', '0134',       '1955-01-01', '1985-03-10', 'B Parcieux : Trévoux jusqu''à Reyrieux'),
('26161', 'circo',  '01-03@1958', '1958-01-01', '1986-11-24', 'B Parcieux : circo de Trévoux'),
('31363', 'canton', '0134',       '1955-01-01', '1985-03-10', 'B Sainte-Euphémie : Trévoux jusqu''à Reyrieux'),
('31363', 'circo',  '01-03@1958', '1958-01-01', '1986-11-24', 'B Sainte-Euphémie : circo de Trévoux'),
('14351', 'canton', '0103',       '1955-01-01', '1962-08-27', 'B Forens : Bellegarde jusqu''à Chézery-Forens'),
('14351', 'circo',  '01-02@1958', '1958-01-01', '1962-08-27', 'B Forens : circo de Bellegarde'),
('10884', 'canton', '0115',       '1955-01-01', '1964-09-01', 'B Lacoux : Hauteville jusqu''à Hauteville-Lompnes'),
('10884', 'circo',  '01-02@1958', '1958-01-01', '1964-09-01', 'B Lacoux : circo de Hauteville'),
('19915', 'canton', '0115',       '1955-01-01', '1964-09-01', 'B Longecombe : Hauteville jusqu''à Hauteville-Lompnes'),
('19915', 'circo',  '01-02@1958', '1958-01-01', '1964-09-01', 'B Longecombe : circo de Hauteville'),
('28114', 'canton', '0117',       '1955-01-01', '1965-01-10', 'B Proulieu : Lagnieu jusqu''à la fusion'),
('28114', 'circo',  '01-03@1958', '1958-01-01', '1965-01-10', 'B Proulieu : circo de Lagnieu'),
('39634', 'canton', '0114',       '1955-01-01', '1965-02-15', 'B Vésenex-Crassy : Gex jusqu''à Divonne'),
('39634', 'circo',  '01-02@1958', '1958-01-01', '1965-02-15', 'B Vésenex-Crassy : circo de Gex'),
('38806', 'canton', '0112',       '1955-01-01', '1966-03-23', 'B Coupy : Collonges jusqu''à Bellegarde'),
('38806', 'circo',  '01-02@1958', '1958-01-01', '1966-03-23', 'B Coupy : circo de Collonges'),
('40987', 'canton', '0116',       '1955-01-01', '1973-03-01', 'B Volognat : Izernore jusqu''à Nurieux-Volognat'),
('40987', 'circo',  '01-02@1958', '1958-01-01', '1973-03-01', 'B Volognat : circo d''Izernore'),
('8382',  'canton', '0109',       '1955-01-01', '1974-01-01', 'B Charancin : Champagne jusqu''à Sutrieu'),
('8382',  'circo',  '01-02@1958', '1958-01-01', '1974-01-01', 'B Charancin : circo de Champagne'),
-- C. 1973-1998, aucun acte
('15331', 'canton', '0122',       '1973-09-23', '1998-03-15', 'C Béard-Géovreissiat : Nantua'),
('15331', 'circo',  '01-02@1958', '1958-01-01', '1986-11-24', 'C Béard-Géovreissiat : circo de Nantua'),
('3535',  'canton', '0136',       '1973-09-23', '1974-11-01', 'C Belmont : Virieu-le-Grand jusqu''à la fusion'),
('3535',  'canton', '0109',       '1974-11-01', '1998-03-15', 'C Belmont-Luthézieu : Champagne (inférence)'),
('3535',  'circo',  '01-02@1958', '1958-01-01', '1986-11-24', 'C Belmont-Luthézieu : circo de Virieu et Champagne'),
('20419', 'canton', '0109',       '1973-09-23', '1974-11-01', 'C Luthézieu : Champagne jusqu''à la fusion'),
('20419', 'circo',  '01-02@1958', '1958-01-01', '1974-11-01', 'C Luthézieu : circo de Champagne'),
-- C bis. coupées au 1973-09-23 (acte de Bourg), fusionnées après
('575',   'canton', '0130',       '1973-09-23', '1974-01-01', 'C Amareins : Saint-Trivier-sur-Moignans jusqu''à la fusion'),
('575',   'circo',  '01-03@1958', '1958-01-01', '1974-01-01', 'C Amareins : circo de Saint-Trivier'),
('7560',  'canton', '0130',       '1973-09-23', '1974-01-01', 'C Cesseins : Saint-Trivier-sur-Moignans jusqu''à la fusion'),
('7560',  'circo',  '01-03@1958', '1958-01-01', '1974-01-01', 'C Cesseins : circo de Saint-Trivier'),
('22656', 'canton', '0113',       '1973-09-23', '1975-01-01', 'C Moëns : Ferney-Voltaire jusqu''à Prévessin-Moëns'),
('22656', 'circo',  '01-02@1958', '1958-01-01', '1975-01-01', 'C Moëns : circo de Ferney-Voltaire');

-- Une fenêtre à vider sur un atome qui n'existe pas n'a rien à vider : depuis
-- la correction des codes de 1968 dans `58` (21 octobre 2026), `59` ne crée
-- plus les fractions de Viriat.
DELETE FROM c121_cible c
 WHERE c.unit_id IS NULL
   AND NOT EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = c.atom_id);

-- La fenêtre de chaque (atome, niveau), et le contrôle qu'elle est sans trou.
CREATE TEMP TABLE c121_fenetre AS
SELECT atom_id, niveau, min(valid_from) AS f_from, max(valid_to) AS f_to,
       sum(valid_to - valid_from) AS jours
  FROM c121_cible GROUP BY atom_id, niveau;

DO $$
DECLARE n int;
BEGIN
    SELECT count(*) INTO n FROM c121_fenetre WHERE jours <> f_to - f_from;
    IF n > 0 THEN RAISE EXCEPTION '121 : % fenêtre(s) à trou ou à chevauchement', n; END IF;
    SELECT count(*) INTO n FROM c121_cible c
     WHERE NOT EXISTS (SELECT 1 FROM atom a WHERE a.atom_id = c.atom_id);
    IF n > 0 THEN RAISE EXCEPTION '121 : % atome(s) inconnu(s)', n; END IF;
    SELECT count(*) INTO n FROM c121_cible c
     WHERE c.unit_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM unit u WHERE u.unit_id = c.unit_id AND u.niveau = c.niveau);
    IF n > 0 THEN RAISE EXCEPTION '121 : % unité(s) inconnue(s)', n; END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Ce que la base porte dans les fenêtres, avant
-- ---------------------------------------------------------------------------
\echo '== Périodes existantes touchées (avant) :'
SELECT m.atom_id, m.niveau, m.unit_id, m.valid_from, m.valid_to,
       CASE WHEN m.valid_from >= f.f_from AND m.valid_to <= f.f_to THEN 'retirée'
            ELSE 'raccourcie' END AS sort
  FROM membership m JOIN c121_fenetre f USING (atom_id, niveau)
 WHERE m.periode && daterange(f.f_from, f.f_to)
 ORDER BY 1, 2, 4;

-- ---------------------------------------------------------------------------
-- 4. Retirer, raccourcir, insérer
-- ---------------------------------------------------------------------------
WITH r AS (
    DELETE FROM membership m USING c121_fenetre f
     WHERE m.atom_id = f.atom_id AND m.niveau = f.niveau
       AND m.valid_from >= f.f_from AND m.valid_to <= f.f_to
    RETURNING m.*)
INSERT INTO p121_trace (quoi, membership_id, atom_id, unit_id, niveau, ancien_from, ancien_to)
SELECT 'retire', membership_id, atom_id, unit_id, niveau, valid_from, valid_to FROM r;

INSERT INTO p121_trace (quoi, membership_id, ancien_from, ancien_to)
SELECT 'modifie', m.membership_id, m.valid_from, m.valid_to
  FROM membership m JOIN c121_fenetre f USING (atom_id, niveau)
 WHERE m.periode && daterange(f.f_from, f.f_to);

-- Une période qui déborde des deux côtés est coupée : sa partie gauche est
-- raccourcie avec les autres, sa partie droite insérée ensuite (tracée
-- « insere »). Mémorisée d'abord : le raccourci la fait sortir du filtre.
CREATE TEMP TABLE c121_coupe AS
SELECT m.atom_id, m.unit_id, m.niveau, f.f_to AS valid_from, m.valid_to
  FROM membership m JOIN c121_fenetre f USING (atom_id, niveau)
 WHERE m.valid_from < f.f_from AND m.valid_to > f.f_to;

UPDATE membership m SET valid_to = f.f_from
  FROM c121_fenetre f
 WHERE m.atom_id = f.atom_id AND m.niveau = f.niveau
   AND m.valid_from < f.f_from AND m.valid_to > f.f_from;
UPDATE membership m SET valid_from = f.f_to
  FROM c121_fenetre f
 WHERE m.atom_id = f.atom_id AND m.niveau = f.niveau
   AND m.valid_from < f.f_to AND m.valid_to > f.f_to;

WITH i AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, valid_from, valid_to FROM c121_coupe
    RETURNING membership_id)
INSERT INTO p121_trace (quoi, membership_id) SELECT 'insere', membership_id FROM i;

WITH i AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, niveau, valid_from, valid_to
      FROM c121_cible WHERE unit_id IS NOT NULL
    RETURNING membership_id)
INSERT INTO p121_trace (quoi, membership_id) SELECT 'insere', membership_id FROM i;

-- ---------------------------------------------------------------------------
-- 5. Bilan
-- ---------------------------------------------------------------------------
\echo '== Bilan de la trace :'
SELECT quoi, count(*) FROM p121_trace GROUP BY quoi ORDER BY quoi;

\echo '== Ce qui est posé :'
SELECT c.atom_id, c.niveau, coalesce(c.unit_id, '(vidé)') AS unit_id, u.nom,
       c.valid_from, c.valid_to, c.motif
  FROM c121_cible c LEFT JOIN unit u ON u.unit_id = c.unit_id AND u.niveau = c.niveau
 ORDER BY c.motif, c.niveau, c.valid_from;

-- Contrôle : plus aucun atome passé par l'Ain sans canton ni circonscription
-- entre 1941 et 1998, hors morts et naissances (fusions, créations) que la
-- trame ANR date d'elle-même.
\echo '== Atomes de l''Ain absents des deux couches une année où ANR les dessine (1941-1998) :'
WITH ain AS (
    SELECT DISTINCT m.atom_id FROM membership m JOIN unit u USING (unit_id, niveau)
     WHERE u.dep = '01'),
an AS (SELECT make_date(y, 12, 1) AS d FROM generate_series(1941, 1998) y)
SELECT a.atom_id, at.insee_geofla, min(an.d) AS de, max(an.d) AS a, count(*) AS annees
  FROM ain a JOIN atom at USING (atom_id) CROSS JOIN an
 WHERE EXISTS (SELECT 1 FROM atom_geom_anr g WHERE g.atom_id = a.atom_id AND g.periode @> an.d)
   AND NOT EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = a.atom_id AND m.periode @> an.d)
   AND NOT EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = a.atom_id AND m.valid_to <= an.d
                     AND NOT EXISTS (SELECT 1 FROM membership m2 WHERE m2.atom_id = a.atom_id
                                       AND m2.valid_from > an.d))
 GROUP BY 1, 2 ORDER BY 3, 2;

\if :poser
\echo '== 121 POSÉ (COMMIT).'
COMMIT;
\else
\echo '== 121 ESSAI : ROLLBACK. Relancer avec -v poser=on pour écrire.'
ROLLBACK;
\endif
