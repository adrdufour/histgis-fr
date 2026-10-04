-- ============================================================================
-- histgis — 12_conflit_successeur.sql : anatomie des 138 désaccords
--
-- Le contrôle Gay laisse 148 atomes mal placés en 1870, dont 138 en
-- `source = 'successeur'` — 9,3 % de cette catégorie. Ils se concentrent en
-- Haute-Marne, Deux-Sèvres et Marne, les trois seuls départements où nous
-- revendiquons du territoire de trop.
--
-- L'hypothèse à tester avant de corriger quoi que ce soit
-- -------------------------------------------------------
-- Ce ne sont probablement PAS des erreurs d'attribution. Le membership dit
-- sans doute vrai ; c'est la géométrie qui ment, et par construction.
--
-- Une commune A de 1870 absorbée depuis par B n'a plus de polygone propre en
-- 2011. `06_insee_mvt.sql` lui donne celui de B — c'est-à-dire A ∪ B. Mais B
-- existe aussi comme atome en 1870, et reçoit le même polygone par jointure
-- directe. Deux atomes, un seul polygone, chacun trop grand de la part de
-- l'autre.
--
-- Tant que A et B sont dans le même canton, l'union les recolle et rien ne
-- paraît. Quand ils sont dans des cantons différents, les deux cantons
-- s'étendent l'un sur l'autre — et le point intérieur de l'atome A tombe
-- souvent chez B, ce que le contrôle enregistre comme un désaccord.
--
-- Si c'est bien cela, le correctif n'est pas dans les attributions mais dans
-- la trame, et il ne peut pas venir de GEOFLA 2011 : une géographie ne se
-- découpe pas plus fin qu'elle-même. Il viendrait d'ANR-COMMUNES.
--
-- Ce fichier ne corrige rien. Il mesure, pour savoir s'il y a lieu de
-- corriger et jusqu'où on pourrait aller.
--
-- Verdict, une fois lancé : l'hypothèse tient. `desaccord_hors_conflit` vaut
-- zéro pour les 138 `successeur`, et les 5 désaccords `hac`/`hac_partage`
-- s'avèrent eux aussi sur des polygones partagés — visibles seulement depuis
-- que la clé est géométrique. Il reste 3 désaccords hors conflit sur 38 235
-- atomes, qui sont les 3 paris perdus du correctif de scission.
--
-- Prérequis : base chargée, puis controle_gay.sh (pour ctrl_atome).
-- Lecture seule, hormis les tables `conflit_*` recréées à chaque passage.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;
\set date_ref '1870-06-01'

DO $$
BEGIN
    IF to_regclass('histgis.ctrl_atome') IS NULL THEN
        RAISE EXCEPTION 'ctrl_atome absente : lancer controle_gay.sh avant.';
    END IF;
    IF to_regclass('histgis.commune_successeur') IS NULL THEN
        RAISE EXCEPTION 'commune_successeur absente : lancer 06_insee_mvt.sql avant.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. À quel polygone de 2011 chaque atome se rattache-t-il ?
--
-- La clé de partage est `cle_geom`, l'empreinte binaire du polygone. C'est la
-- seule qui ne suppose rien : dans `05`, deux atomes portant le même polygone
-- reçoivent une géométrie construite par le même ST_UnaryUnion(ST_Collect(...))
-- sur le même jeu de communes GEOFLA, donc identique bit à bit.
--
-- `code_2011` est conservé comme étiquette lisible — il nomme le polygone en
-- clair — mais il ne sert plus à grouper. Il valait
-- `coalesce(cs.insee_2011, d.cible, a.insee_geofla)`, un coalesce aveugle à
-- `atom_geom.source` : les 17 atomes `hac`/`hac_partage`, rattachés par nom,
-- retombaient sur un code d'époque absent de GEOFLA et formaient chacun un
-- groupe d'un seul, alors que leur polygone est porté par d'autres atomes.
-- Coût du défaut : 108 km² de double comptage invisibles, établi par `14`.
-- Deux bénéfices au passage : `max(km2_polygone)` cesse d'être une
-- approximation, tous les membres d'un groupe ayant la même géométrie ; et
-- `n_codes` > 1 signale les groupes que l'ancienne clé séparait.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS conflit_atome;
CREATE TABLE conflit_atome AS
SELECT m.atom_id,
       m.unit_id,
       u.dep,
       a.insee_geofla                       AS insee_epoque,
       ag.source,
       md5(ST_AsEWKB(ag.geom))              AS cle_geom,
       coalesce(cs.insee_2011, d.cible, a.insee_geofla) AS code_2011,
       round((ST_Area(ag.geom) / 1e6)::numeric, 2)      AS km2_polygone,
       ca.pct_nous,
       ca.pct_gay,
       (ca.pct_nous IS DISTINCT FROM ca.pct_gay)        AS desaccord
FROM   membership m
JOIN   atom a       ON a.atom_id = m.atom_id
JOIN   atom_geom ag ON ag.atom_id = m.atom_id
JOIN   unit u       ON u.unit_id = m.unit_id AND u.niveau = 'canton'
LEFT   JOIN commune_successeur cs ON cs.insee_ancien = a.insee_geofla
LEFT   JOIN diag_geom_correspondance d ON d.insee = a.insee_geofla
LEFT   JOIN ctrl_atome ca ON ca.atom_id = m.atom_id
                         AND ca.annee = extract(year FROM :'date_ref'::date)::int
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'date_ref'::date;

CREATE INDEX conflit_atome_cle_idx  ON conflit_atome (cle_geom);
CREATE INDEX conflit_atome_code_idx ON conflit_atome (code_2011);

-- ---------------------------------------------------------------------------
-- 2. Les groupes de partage, et lesquels sont éclatés entre cantons
--
-- `unites` > 1 : le même polygone est réclamé par plusieurs cantons. Comme
-- `snapshot_geom` unionne par unité, la surface est alors comptée autant de
-- fois qu'il y a d'unités — d'où `km2_en_trop`.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS conflit_groupe;
CREATE TABLE conflit_groupe AS
SELECT cle_geom,
       count(*)                                    AS atomes,
       count(DISTINCT unit_id)                     AS unites,
       count(DISTINCT dep)                         AS departements,
       max(km2_polygone)                           AS km2_polygone,
       max(km2_polygone) * (count(DISTINCT unit_id) - 1) AS km2_en_trop,
       count(*) FILTER (WHERE desaccord)           AS atomes_en_desaccord,
       count(DISTINCT code_2011)                   AS n_codes,
       string_agg(DISTINCT source, ',' ORDER BY source)     AS sources,
       string_agg(DISTINCT code_2011, ';' ORDER BY code_2011) AS codes_2011,
       string_agg(DISTINCT unit_id, ';' ORDER BY unit_id)   AS unit_ids,
       -- dep est char(2) : le cast évite un litige de signature sur string_agg
       string_agg(DISTINCT dep::text, ';' ORDER BY dep::text) AS deps
FROM   conflit_atome
GROUP  BY cle_geom;

CREATE INDEX conflit_groupe_idx ON conflit_groupe (unites, km2_en_trop);
CREATE INDEX conflit_groupe_cle_idx ON conflit_groupe (cle_geom);

-- ---------------------------------------------------------------------------
-- 3. Rapport
-- ---------------------------------------------------------------------------
\echo ''
\echo '============================================================'
\echo ' CONFLITS DE POLYGONE — pourquoi les atomes `successeur`'
\echo ' tombent-ils dans le mauvais canton ?'
\echo '============================================================'
\echo '(date de référence : 1870-06-01)'

\echo ''
\echo '=== 1. Le désaccord suit-il le partage de polygone ? ==='
\echo '    Si l''hypothèse tient, le taux de désaccord doit être nul chez les'
\echo '    atomes seuls sur leur polygone, et concentré chez ceux dont le'
\echo '    groupe est éclaté entre plusieurs cantons.'
SELECT CASE WHEN g.atomes = 1        THEN '1. seul sur son polygone'
            WHEN g.unites = 1        THEN '2. partage, meme canton'
            ELSE                          '3. partage, cantons differents'
       END                                                   AS situation,
       count(*)                                              AS atomes,
       count(*) FILTER (WHERE c.desaccord)                   AS en_desaccord,
       round(100.0 * count(*) FILTER (WHERE c.desaccord) / count(*), 2) AS pct
FROM   conflit_atome c JOIN conflit_groupe g USING (cle_geom)
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '--- même chose, croisée avec la source de la géométrie ---'
SELECT c.source,
       count(*)                                                   AS atomes,
       count(*) FILTER (WHERE g.unites > 1)                       AS dans_groupe_eclate,
       count(*) FILTER (WHERE c.desaccord)                        AS en_desaccord,
       count(*) FILTER (WHERE c.desaccord AND g.unites = 1)       AS desaccord_hors_conflit
FROM   conflit_atome c JOIN conflit_groupe g USING (cle_geom)
GROUP  BY c.source ORDER BY 4 DESC;

\echo ''
\echo '    La colonne `desaccord_hors_conflit` est la seule qui accuserait'
\echo '    vraiment les attributions. Si elle est proche de zéro, le'
\echo '    membership est sain et c''est la trame qui est en cause.'

\echo ''
\echo '=== 2. Volumétrie des conflits ==='
SELECT count(*)                                   AS groupes,
       count(*) FILTER (WHERE atomes > 1)         AS groupes_partages,
       count(*) FILTER (WHERE unites > 1)         AS groupes_eclates,
       count(*) FILTER (WHERE departements > 1)   AS eclates_entre_departements,
       count(*) FILTER (WHERE n_codes > 1)                     AS codes_multiples,
       count(*) FILTER (WHERE n_codes > 1 AND unites > 1)      AS codes_multiples_eclates,
       round(sum(km2_en_trop), 0)                 AS km2_comptes_en_double
FROM   conflit_groupe;

\echo ''
\echo '    ATTENTION : ce chiffre ne doit PAS ressembler aux 3 945 km² de la'
\echo '    section 3 de 08. Ici on compte entre CANTONS RÉELS ; 08 compte sur'
\echo '    ctrl_nous, dissous par deppct, donc APRÈS repliement en'
\echo '    pseudo-cantons — et le repliement réunit précisément les cantons qui'
\echo '    se partagent une commune. L''écart est le repliement lui-même :'
\echo '    12 930 = 8 985 absorbés + 3 945 résiduels. Établi par 13.'
\echo ''
\echo '    `codes_multiples` : polygones que l''ancienne clé code_2011 séparait'
\echo '    à tort — 15. Seuls les 5 qui sont AUSSI éclatés entre cantons'
\echo '    coûtent quelque chose : 108 km², invisibles avant (cf. 14). Les 10'
\echo '    autres tiennent dans un seul canton, donc sans double comptage.'

\echo ''
\echo '=== 3. Les 25 groupes les plus coûteux ==='
SELECT left(g.codes_2011, 24) AS codes_2011, g.n_codes,
       g.atomes, g.unites, g.departements,
       g.km2_polygone, round(g.km2_en_trop, 1) AS km2_en_trop,
       g.atomes_en_desaccord, g.sources, g.deps, left(g.unit_ids, 40) AS unites_ids
FROM   conflit_groupe g
WHERE  g.unites > 1
ORDER  BY g.km2_en_trop DESC LIMIT 25;

\echo ''
\echo '=== 4. Par département : conflits et excédent constaté ==='
\echo '    `km2_nous_seul` vient de ctrl_dep : c''est le territoire que nous'
\echo '    revendiquons et que Gay place ailleurs. Haute-Marne 130,1,'
\echo '    Deux-Sèvres 88,1, Marne 59,0.'
\echo '    Un groupe à cheval sur deux départements est compté dans les deux :'
\echo '    la colonne km2_en_double se lit par département, pas en total.'
WITH par_dep AS (
    SELECT c.dep,
           count(DISTINCT c.cle_geom) FILTER (WHERE g.unites > 1) AS groupes_eclates,
           count(*) FILTER (WHERE c.desaccord)                     AS atomes_en_desaccord
    FROM   conflit_atome c JOIN conflit_groupe g USING (cle_geom)
    GROUP  BY c.dep
),
trop AS (
    SELECT dc.dep, round(sum(g.km2_en_trop), 1) AS km2_en_double
    FROM   (SELECT DISTINCT dep, cle_geom FROM conflit_atome) dc
    JOIN   conflit_groupe g USING (cle_geom)
    WHERE  g.unites > 1
    GROUP  BY dc.dep
)
SELECT p.dep, p.groupes_eclates, p.atomes_en_desaccord, t.km2_en_double,
       d.km2_nous_seul, d.km2_gay_seul
FROM   par_dep p
LEFT   JOIN trop t     ON t.dep = p.dep
LEFT   JOIN ctrl_dep d ON d.annee = extract(year FROM :'date_ref'::date)::int
                      AND d.dep = p.dep
WHERE  p.atomes_en_desaccord > 0
ORDER  BY p.atomes_en_desaccord DESC LIMIT 20;

\echo ''
\echo '=== 5. Haute-Marne : le détail ==='
\echo '    Trois cantons y portent l''essentiel de l''écart — Fayl-Billot,'
\echo '    Clefmont, Vignory. Voici ce que chaque atome litigieux y apporte.'
SELECT c.atom_id, c.insee_epoque, c.code_2011, c.source,
       c.unit_id, c.pct_nous AS chez_nous, c.pct_gay AS chez_gay,
       c.km2_polygone, g.atomes, g.unites, g.unit_ids
FROM   conflit_atome c JOIN conflit_groupe g USING (cle_geom)
WHERE  c.dep = '52' AND c.desaccord
ORDER  BY c.km2_polygone DESC;

\echo ''
\echo '=== 6. Le plafond : que resterait-il avec une attribution parfaite ? ==='
\echo '    Même en supposant tous les rattachements exacts, un polygone'
\echo '    partagé entre deux cantons reste indivisible sur la trame 2011.'
\echo '    Cette surface est le plancher d''erreur de la trame, et seule une'
\echo '    trame communale historique — ANR-COMMUNES — peut l''abaisser.'
\echo '    Lu ici entre cantons réels. Le chiffre à citer en note de méthode'
\echo '    est celui d''APRÈS repliement — 3 945 km² —, seul niveau où les deux'
\echo '    sources sont commensurables. Voir 13 § 1.'
SELECT round(sum(km2_polygone), 0)                                     AS km2_polygones_eclates,
       round(sum(km2_en_trop), 0)                                      AS km2_incompressibles,
       round(100.0 * sum(km2_en_trop) / (SELECT sum(km2_polygone) FROM conflit_groupe), 3)
                                                                       AS pct_du_territoire
FROM   conflit_groupe WHERE unites > 1;

\echo ''
\echo 'Tables : conflit_atome, conflit_groupe (clé : cle_geom).'
