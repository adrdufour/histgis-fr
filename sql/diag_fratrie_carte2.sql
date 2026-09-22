-- ============================================================================
-- histgis — diag_fratrie_carte2.sql : les sœurs que le premier passage n'a pas
-- vues, et la question qu'il laissait ouverte
--
--     psql -d histgis -f sql/diag_fratrie_carte2.sql
--
-- LECTURE SEULE, quelques secondes : deux passes départementales, 47 et 50.
--
-- CE QUE LE PREMIER FICHIER A ÉTABLI, LE 5 SEPTEMBRE 2026
-- -------------------------------------------------------
--     47  BOURLENS           reprise 73,518  carte 73,518  repli 15,578
--     47  COURBIAC           reprise  0,000  carte  ——     repli  9,013
--     50  ROCHEVILLE         reprise 19,080  carte 19,080  repli 10,417
--     50  L'ÉTANG-BERTRAND   reprise  0,000  carte  ——     repli  8,525
--     47  TOURNON-D'AGENAIS  ANR 94,956  →  carte 21,438
--     50  BRICQUEBEC         ANR 52,046  →  carte 32,966
--
-- TROIS FAITS, ET LE PREMIER EST LE PLUS DUR.
--
-- 1. **Les deux muettes n'ont AUCUNE ligne sur la carte.** `km2_carte` est nul,
--    `source` est nul : elles ne sortent pas de `partition_un_dep`. Elles ne
--    sont donc comptées ni en `reprise`, ni en `repli` — elles sont dans les
--    **318 atomes absents du résultat** du § 8 de `diag_partition.sql`. Voilà
--    pourquoi le compte des replis n'a pas bougé d'un pouce après le correctif
--    du matin : ces deux-là ne sont dans aucun compte.
--
--    *Un polygone d'aire nulle entre dans le treillis, ne borde rien, ne gagne
--    aucune face, et disparaît. « Servie avec rien » et « absente du résultat »
--    ne sont pas deux symptômes : c'est le même, à deux étapes de distance.*
--
-- 2. **Le treillis ne répare pas l'entrée, il l'entérine.** Bourlens garde ses
--    73,518 km² pour un repli de 15,578 ; Rocheville 19,080 pour 10,417.
--
-- 3. **Et la soustraction est exacte, ce qui explique le silence des recettes.**
--    94,956 − 73,518 = 21,438 au km² près ; 52,046 − 19,080 = 32,966. La mère
--    rend exactement ce que l'unique sœur servie reçoit. La somme est
--    conservée, l'emprise nationale ne bouge pas, le recouvrement reste nul.
--    **Sur la carte, là où il devrait y avoir six communes, il y en a une.**
--
-- CE QUE CE FICHIER-CI VA CHERCHER, ET POURQUOI
-- ---------------------------------------------
-- Le premier passage a bâti sa liste de filles sur `partition_reprise(date,
-- NULL)`, qui ne rend QUE les filles servies. Anthé, Thézac, Masquières et
-- Cazideroque n'y sont pas — ce sont des muettes au national. Elles ont donc
-- échappé au tableau, et les passes de 46 et 82 n'ont même pas été calculées.
--
-- *Une liste bâtie sur le résultat d'une règle ne peut pas contenir ceux que la
-- règle laisse dehors. C'est la troisième fois aujourd'hui.*
--
-- La question ouverte est celle-ci : Anthé et Thézac reçoivent le MÊME morceau
-- de 73,518 km² que Bourlens dans les passes de 82 et 46. Sont-elles dessinées
-- avec ? Si oui, le même sol est sur la carte trois fois et la ligne « couture
-- entre départements » devrait valoir 70 et non 0,019. Si non — et c'est ce que
-- 0,019 laisse attendre —, c'est que `partition_un_dep` ne rend que les atomes
-- `dedans`, et qu'une fille ne gagne ses faces que dans SON département.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?date}
\else
    \set date '1870-12-01'
\endif

\echo ''
\echo '--- Les six filles de Tournon-d''Agenais et les deux de Bricquebec ------'
\echo '    Bâties sur les CANDIDATES et non sur les servies : vivantes à la'
\echo '    date, non-fractions, sans polygone ANR alors, dont ANR reparle en'
\echo '    1876 (resp. 1895), et dont le repli touche le polygone de la mère.'
\echo '    C''est la définition qu''emploie `partition_reprise` elle-même, prise'
\echo '    AVANT l''arbitrage — donc muettes comprises.'
\echo ''

DROP TABLE IF EXISTS dfc2;
CREATE TEMP TABLE dfc2 AS
WITH mere AS (
    SELECT g.atom_id, g.geom
    FROM   atom_geom_anr g
    WHERE  g.atom_id IN ('37892', '5988') AND g.periode @> :'date'::date
),
candidate AS (
    SELECT DISTINCT m.atom_id
    FROM   membership m
    JOIN   atom a ON a.atom_id = m.atom_id
    WHERE  m.periode @> :'date'::date AND NOT a.fraction
      AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g
                        WHERE g.atom_id = m.atom_id AND g.periode @> :'date'::date)
)
SELECT c.atom_id,
       me.atom_id                                       AS mere_id,
       extract(year FROM min(lower(g.periode)))::int    AS y_prime,
       (SELECT min(u.dep)
          FROM membership m
          JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
         WHERE m.atom_id = c.atom_id AND m.periode @> :'date'::date) AS dep,
       ST_Area(ag.geom)                                 AS m2_repli
FROM   candidate c
JOIN   atom_geom ag ON ag.atom_id = c.atom_id
JOIN   mere me ON ST_Intersects(me.geom, ag.geom)
JOIN   atom_geom_anr g ON g.atom_id = c.atom_id AND lower(g.periode) > :'date'::date
GROUP  BY c.atom_id, me.atom_id, ag.geom
HAVING extract(year FROM min(lower(g.periode)))::int
       = CASE WHEN me.atom_id = '37892' THEN 1876 ELSE 1895 END;

SELECT d.mere_id, d.atom_id,
       coalesce(n.nom, '[' || a.insee_geofla || ']')    AS nom,
       d.dep, d.y_prime,
       round((d.m2_repli / 1e6)::numeric, 3)            AS km2_repli
FROM   dfc2 d
JOIN   atom a ON a.atom_id = d.atom_id
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
ORDER  BY d.mere_id, 6 DESC;

\echo ''
\echo '=== La question : chacune est-elle DESSINÉE dans son propre département ?'
\echo '    `sur_la_carte = f` pour toutes sauf une par fratrie ⇒ le treillis'
\echo '    n''entérine qu''une seule sœur, les autres tombent dans les 318, et'
\echo '    le triple don de 73,518 km² ne se voit pas sur le dessin — ce que'
\echo '    les 0,019 km² de couture laissaient attendre.'
\echo '    Plusieurs `t` avec des surfaces franches ⇒ le même sol est dessiné'
\echo '    plusieurs fois, et c''est la couture qui ment.'
\echo ''

\timing on
SELECT d.mere_id, d.atom_id,
       coalesce(n.nom, '[' || a.insee_geofla || ']')    AS nom,
       d.dep,
       round((d.m2_repli / 1e6)::numeric, 3)            AS km2_repli,
       c.atom_id IS NOT NULL                            AS sur_la_carte,
       round((ST_Area(c.geom) / 1e6)::numeric, 3)       AS km2_carte,
       c.source, c.motif
FROM   dfc2 d
JOIN   atom a ON a.atom_id = d.atom_id
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
LEFT   JOIN LATERAL (
       SELECT * FROM partition_un_dep(:'date'::date, d.dep) p
        WHERE p.atom_id = d.atom_id) c ON true
ORDER  BY d.mere_id, 5 DESC;
\timing off

\echo ''
\echo '--- Fin. `dfc2` reste disponible dans CETTE session.'
\echo ''
