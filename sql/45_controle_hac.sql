-- ============================================================================
-- 45_controle_hac.sql — confronter les paris de `11` à la filiation de HAC
--
--   python3 annexes/hac/hac_filiation.py            # produit le CSV
--   psql -d histgis -f sql/45_controle_hac.sql   # depuis la RACINE du dépôt
--
-- **CE FICHIER NE MODIFIE RIEN.** Aucun INSERT, aucun DELETE, aucun UPDATE sur
-- `membership`. C'est un contrôle, pas un correctif — et il doit le rester :
-- corriger la base d'après HAC ferait perdre à HAC son indépendance, exactement
-- comme recopier Gay ferait perdre la sienne au contrôle géométrique.
--
-- Ce qu'on contrôle
-- -----------------
-- `11_scission.sql` prolonge vers 1870 les communes nées PENDANT la série, sur
-- le pari : « une commune nouvelle reste dans le canton de sa mère ». Il fait ce
-- pari **sans savoir qui est la mère** — il ne dispose que de la géométrie et
-- des cantons. 414 atomes ont été prolongés, dont 4 à tort selon le contrôle
-- Gay ; `METHODE.md` note que ces quatre « se tranchent sur pièces d'archives ».
--
-- HAC nomme la mère. Pour 444 créations de la fenêtre 1870-1941 sur 447, la
-- filiation est résolue de façon unique (`annexes/hac/hac_filiation.py`, 99,3 %). C'est
-- une voie indépendante : `11` raisonne par voisinage cantonal, HAC lit un acte.
--
-- La question posée
-- -----------------
--   « À la date où `11` a prolongé un atome vers l'arrière, la mère que HAC
--     nomme relevait-elle bien de l'unité que `11` a posée ? »
--
--   accord            -> le pari est confirmé par une source qui nomme la mère
--   désaccord         -> le pari est contredit : à examiner, pièce en main
--   mere_muette       -> HAC nomme une mère que la base ne rattache pas à cette
--                        date : le contrôle ne dit rien, il ne condamne pas
--   hors_hac          -> aucune filiation résolue : HAC ne couvre pas ce cas
--
-- Ce que le contrôle NE prouve pas
-- --------------------------------
-- Un accord confirme que la mère nommée était dans la même unité — pas que
-- `11` a « trouvé » la bonne mère, puisqu'il n'en cherchait aucune. C'est bien
-- ce qui nous intéresse : le pari porte sur l'UNITÉ, pas sur la filiation.
--
-- Et un désaccord n'est pas nécessairement une erreur de `11` : il peut venir
-- d'une mère mal résolue par le nom, ou d'une commune née d'un démembrement
-- entre plusieurs communes, dont HAC ne cite que la première. Chaque désaccord
-- se lit, il ne se compte pas seulement.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- Chemin du CSV produit par `annexes/hac/hac_filiation.py`.
--
-- `\copy` résout les chemins relatifs depuis le répertoire d'où `psql` est
-- lancé, PAS depuis le fichier .sql — d'où le défaut relatif à la racine du
-- dépôt, qui est là d'où ce fichier se joue :
--
--     psql -d histgis -f sql/45_controle_hac.sql
--
-- Depuis ailleurs, passer le chemin :
--
--     psql -d histgis -v hac=/chemin/hac_filiation.csv -f sql/45_controle_hac.sql
\if :{?hac}
\else
  \set hac 'annexes/hac/hac_filiation.csv'
\endif

DO $$
BEGIN
    IF to_regclass('histgis.scission_trace') IS NULL THEN
        RAISE EXCEPTION '11_scission.sql doit avoir été joué : sa trace est '
                        'l''objet même du contrôle.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. La filiation de HAC
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS hac_filiation;
CREATE TABLE hac_filiation (
    cassini_fille text,
    nom_fille     text,
    dep           text,
    annee         int,
    nom_mere_hac  text,
    cassini_mere  text,
    voie          text
);
\set cmd '\\copy hac_filiation FROM ' :'hac' ' WITH (FORMAT csv, HEADER true)'
:cmd
CREATE INDEX hac_filiation_idx ON hac_filiation (cassini_fille);

\echo ''
\echo '=== 1. La filiation extraite de HAC ==='
SELECT voie, count(*) AS creations,
       min(annee) AS plus_ancienne, max(annee) AS plus_recente
  FROM hac_filiation GROUP BY 1 ORDER BY 2 DESC;
-- Mesuré le 20 août 2026 : 444 uniques, 1 homonyme, 2 introuvables sur 447.

-- ---------------------------------------------------------------------------
-- 2. Chaque prolongement de `11`, confronté à la mère nommée
--
-- On interroge la mère à la date de DÉBUT du prolongement. `11` pose des
-- intervalles ; il suffit d'un point dans chacun pour trancher, et le début
-- est celui qui remonte le plus loin — donc le plus exposé.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS ctrl_hac;
CREATE TEMP TABLE ctrl_hac AS
SELECT t.membership_id, t.atom_id, t.niveau,
       t.unit_id                                   AS unite_posee,
       t.valid_from, t.valid_to, t.debut_reel,
       a.insee_geofla, f.nom_fille, f.dep, f.annee,
       f.nom_mere_hac, f.cassini_mere,
       (SELECT mm.unit_id
          FROM atom am
          JOIN membership mm ON mm.atom_id = am.atom_id
                            AND mm.niveau  = t.niveau
                            AND mm.periode @> t.valid_from
         WHERE am.cassini = f.cassini_mere
         ORDER BY mm.unit_id LIMIT 1)              AS unite_mere,
       (SELECT count(DISTINCT mm.unit_id)
          FROM atom am
          JOIN membership mm ON mm.atom_id = am.atom_id
                            AND mm.niveau  = t.niveau
                            AND mm.periode @> t.valid_from
         WHERE am.cassini = f.cassini_mere)        AS n_unites_mere
  FROM scission_trace t
  JOIN atom a ON a.atom_id = t.atom_id
  LEFT JOIN hac_filiation f ON f.cassini_fille = a.cassini
                           AND f.voie = 'unique';

DROP TABLE IF EXISTS ctrl_hac_verdict;
CREATE TEMP TABLE ctrl_hac_verdict AS
SELECT *,
       CASE WHEN cassini_mere IS NULL OR cassini_mere = '' THEN 'hors_hac'
            WHEN unite_mere IS NULL                        THEN 'mere_muette'
            WHEN n_unites_mere > 1                         THEN 'mere_partagee'
            WHEN unite_mere = unite_posee                  THEN 'accord'
            ELSE                                                'desaccord'
       END AS verdict
  FROM ctrl_hac;

\echo ''
\echo '=== 2. Verdict, par niveau ==='
SELECT niveau, verdict, count(*) AS lignes,
       count(DISTINCT atom_id) AS atomes
  FROM ctrl_hac_verdict GROUP BY 1, 2 ORDER BY 1, 3 DESC;

\echo ''
\echo '=== 3. Taux d''accord là où le contrôle parle ==='
SELECT niveau,
       count(*) FILTER (WHERE verdict = 'accord')    AS accords,
       count(*) FILTER (WHERE verdict = 'desaccord') AS desaccords,
       round(100.0 * count(*) FILTER (WHERE verdict = 'accord')
             / nullif(count(*) FILTER (WHERE verdict IN ('accord','desaccord')), 0), 1)
                                                     AS pct_accord
  FROM ctrl_hac_verdict GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 4. Les désaccords, un par un ==='
\echo '    À LIRE, pas à compter. Un désaccord peut venir de 11, mais aussi'
\echo '    d''une mère mal résolue par son nom, ou d''une commune née du'
\echo '    démembrement de PLUSIEURS communes dont HAC ne cite que la première.'
SELECT v.dep, v.annee, coalesce(v.nom_fille, v.insee_geofla) AS fille,
       v.niveau,
       v.unite_posee, coalesce(up.nom, '?') AS nom_unite_posee,
       v.unite_mere,  coalesce(um.nom, '?') AS nom_unite_mere,
       v.nom_mere_hac, v.valid_from
  FROM ctrl_hac_verdict v
  LEFT JOIN unit up ON up.unit_id = v.unite_posee AND up.niveau = v.niveau
  LEFT JOIN unit um ON um.unit_id = v.unite_mere  AND um.niveau = v.niveau
 WHERE v.verdict = 'desaccord'
 ORDER BY v.niveau, v.dep, v.annee;

\echo ''
\echo '=== 5. Les quatre paris que le contrôle Gay dit perdus ==='
\echo '    Mézières/Charleville, Donnemarie/Nangis, Houat et Hœdic.'
\echo '    METHODE.md dit qu''ils « se tranchent sur pièces d''archives ».'
\echo '    HAC est une pièce : que dit-elle ?'
SELECT v.insee_geofla, coalesce(v.nom_fille, '?') AS fille, v.niveau,
       v.unite_posee, v.unite_mere, v.nom_mere_hac, v.verdict
  FROM ctrl_hac_verdict v
 WHERE v.insee_geofla IN ('37390', '08447', '36437', '77454', '17501', '17191')
 ORDER BY v.insee_geofla, v.niveau;

\echo ''
\echo '=== 6. Couverture du contrôle ==='
SELECT count(DISTINCT t.atom_id)                              AS atomes_prolonges_par_11,
       count(DISTINCT v.atom_id) FILTER (WHERE v.verdict <> 'hors_hac')
                                                              AS dont_controles_par_hac
  FROM scission_trace t
  LEFT JOIN ctrl_hac_verdict v ON v.membership_id = t.membership_id;
-- Un écart important signalerait que HAC ne couvre pas la même population :
-- `11` prolonge des atomes nés pendant la série, HAC recense des créations.
-- Les deux ensembles devraient largement se recouvrir, sans coïncider.
