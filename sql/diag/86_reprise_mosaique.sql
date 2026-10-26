-- ============================================================================
-- histgis — 86_reprise_mosaique.sql : la règle de fratrie, avant et après
--
--     psql -d histgis -f sql/diag/86_reprise_mosaique.sql
--
-- CE FICHIER NE POSE RIEN ET NE MODIFIE RIEN. Il compare les deux règles de
-- partage d'une fratrie, toutes deux définies dans `sql/84_carte_partition.sql`
-- et toutes deux vivantes :
--
--     `partition_reprise`          la règle EN VIGUEUR depuis le 5 sept. 2026 ;
--     `partition_reprise_morceau`  la règle HISTORIQUE, plus appelée par rien.
--
-- Il a servi à décider, il sert maintenant à contrôler que la décision tient.
--
-- CE QUI A CHANGÉ, ET POURQUOI
-- -----------------------------
--   HISTORIQUE   le `reste` est déplié par `ST_Dump`, qui ne sépare que les
--                composantes DÉCONNECTÉES ; chaque morceau va à la fille dont
--                le repli le recouvre le plus. Six filles voisines ne font
--                qu'un morceau : une seule sert, les cinq autres ne reçoivent
--                rien, ne gagnent aucune face et sortent du résultat. Mesuré
--                sur la carte le 5 septembre : des six filles de
--                Tournon-d'Agenais, une seule est dessinée, et Bourlens porte
--                73,518 km² pour un repli de 15,578.
--
--   EN VIGUEUR   chaque fille reçoit `reste ∩ son repli` ; le sol qu'aucun
--                repli ne réclame va, ENTRE SŒURS, à celle qui partage avec lui
--                le plus long bord — la règle de comblement du § (e) de `84`,
--                mot pour mot, rendue à la portée où elle a un sens.
--
-- CE QUI A AUTORISÉ LE CHANGEMENT, mesuré avant d'être écrit : la somme des
-- replis des sœurs reproduit le morceau à moins d'un pour cent — 73,793 contre
-- 73,518 pour Tournon-d'Agenais, 18,942 contre 19,080 pour Bricquebec. **La
-- mosaïque des replis PAVE le territoire à partager**, elle ne le devine pas.
-- Le repli reste un indice de POSITION et jamais une mesure de surface, ce que
-- la règle historique affirmait déjà de lui ; ni seuil, ni proportion, ni ligne
-- tracée à la main.
--
-- POURQUOI PAS AU BANC, COMME LES DEUX RÈGLES PRÉCÉDENTES
-- -------------------------------------------------------
-- `sql/bancs/banc_84.py` a reçu la règle mosaïque le 5 septembre 2026 (drapeau
-- `--mosaique`), et **il ne peut plus servir de banc** : son entrée est
-- `cartes/web/donnees/`, dont chaque `dep/NN/index.json` porte désormais
-- `trame: "partition"` depuis l'export du 5 septembre. Lancé sur le
-- Lot-et-Garonne, il annonce 329 atomes ANR, **0 reprise et 0 repli** : il n'a
-- plus rien à reprendre, puisqu'il lit une trame déjà nettoyée.
--
-- *Un banc dont l'entrée est la sortie de ce qu'il éprouve ne prouve rien. Il
-- ne se plaint pas pour autant : il rend des zéros, qui ressemblent à des
-- succès.* Le drapeau est conservé — il redeviendra utile le jour où un export
-- en trame ordinaire sera régénéré — mais la mesure qui a décidé est celle-ci,
-- en SQL, contre la base.
--
-- CE QUE LES QUATRE SECTIONS ONT RENDU LE 5 SEPTEMBRE 2026
-- --------------------------------------------------------
--   § 1  Tournon-d'Agenais : 1 fille dessinée -> 6, somme 73,518 EXACTE.
--        Bricquebec : 1 -> 2, somme 19,080 exacte.
--   § 2  435 servies -> 447 ; 5 469,9 km² en union -> 5 469,9. Le total ligne
--        à ligne vaut 5 475,2, soit **5,3 km² (0,097 %) où deux sœurs
--        réclament le même sol** — le défaut connu des replis qui se
--        recouvrent, laissé au `departage` du treillis, qui est fait pour ça.
--   § 3  reliquat 559,280 km² (10,22 %) avec la mosaïque NUE -> **0,000**
--        avec le comblement intra-fratrie.
--   § 4  aucune fratrie sans propriétaire.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?date}
\else
    \set date '1870-12-01'
\endif

DO $$
BEGIN
    IF to_regprocedure('histgis.partition_reprise_morceau(date, text)') IS NULL
       OR to_regprocedure('histgis.partition_reprise(date, text)') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/84_carte_partition.sql avant celui-ci.';
    END IF;
END $$;

\echo ''
\echo '=== 1. Les deux fratries connues, sous les deux règles =================='
\echo '    Attendu si la règle tient : SIX lignes servies chez Tournon-d''Agenais'
\echo '    au lieu d''une, chacune proche de son repli, et la somme proche de'
\echo '    73,518. Une fille qui perdrait du sol par rapport à l''ancienne règle'
\echo '    ne serait pas une surprise — Bourlens doit précisément en perdre.'
\echo ''

SELECT coalesce(n.nom, '[' || a.insee_geofla || ']')          AS nom,
       v.mere_id, v.fratrie,
       round((ST_Area(ag.geom) / 1e6)::numeric, 3)            AS km2_repli,
       round((ST_Area(o.geom) / 1e6)::numeric, 3)             AS km2_ancienne,
       round((ST_Area(v.geom) / 1e6)::numeric, 3)             AS km2_mosaique
FROM   partition_reprise(:'date'::date, NULL) v
JOIN   atom a ON a.atom_id = v.atom_id
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
LEFT   JOIN atom_geom ag ON ag.atom_id = v.atom_id
LEFT   JOIN partition_reprise_morceau(:'date'::date, NULL) o ON o.atom_id = v.atom_id
WHERE  v.mere_id IN ('37892', '5988')
ORDER  BY v.mere_id, 6 DESC;

\echo ''
\echo '=== 2. Le compte national, règle contre règle ==========================='
\echo '    Mesuré le 5 septembre avec la mosaïque NUE : 435 servies -> 447,'
\echo '    et 5 469,9 km² -> 4 915,9, l''écart étant exactement le reliquat.'
\echo '    Avec le comblement intra-fratrie, `servies` doit rester à 447 et'
\echo '    **le total doit revenir à 5 469,9** : on redistribue du sol entre'
\echo '    sœurs, on n''en perd ni n''en crée. Un total plus bas dirait que du'
\echo '    sol s''évapore ; plus haut, que des sœurs se recouvrent — ce que le'
\echo '    treillis absorberait, mais qu''il vaut mieux voir ici.'
\echo ''

SELECT 'en vigueur (morceau entier)' AS regle, count(*) AS servies,
       round((sum(ST_Area(geom)) / 1e6)::numeric, 1) AS km2_total
FROM   partition_reprise_morceau(:'date'::date, NULL)
UNION ALL
SELECT 'mosaïque (reste ∩ repli)', count(*),
       round((sum(ST_Area(geom)) / 1e6)::numeric, 1)
FROM   partition_reprise(:'date'::date, NULL);

\echo ''
\echo '=== 3. LE RELIQUAT — doit être NUL, et c''est le contrôle du fichier ===='
\echo '    Mesuré le 5 septembre 2026 AVANT le comblement intra-fratrie :'
\echo '    559,280 km², soit 10,22 % du sol à partager, qui seraient partis au'
\echo '    comblement du treillis — cinq fois le comblement national actuel, et'
\echo '    au profit de voisins étrangers à la fratrie. La règle joue donc le'
\echo '    comblement ENTRE SŒURS d''abord. Attendu ici : 0,000 ou l''épaisseur'
\echo '    d''un arrondi. Un chiffre franc voudrait dire que des composantes ne'
\echo '    trouvent aucune sœur, et il faudrait les nommer avant d''aller plus'
\echo '    loin.'
\echo ''

WITH d AS (
    SELECT v.mere_id, v.an_reprise, max(v.fratrie) AS fratrie,
           ST_UnaryUnion(ST_Collect(v.geom))       AS pris
    FROM   partition_reprise(:'date'::date, NULL) v
    GROUP  BY v.mere_id, v.an_reprise
),
o AS (
    SELECT o.mere_id, o.an_reprise,
           ST_UnaryUnion(ST_Collect(o.geom))       AS ancien
    FROM   partition_reprise_morceau(:'date'::date, NULL) o
    GROUP  BY o.mere_id, o.an_reprise
)
SELECT count(*)                                                AS fratries,
       round((sum(ST_Area(o.ancien)) / 1e6)::numeric, 1)        AS km2_a_partager,
       round((sum(ST_Area(d.pris)) / 1e6)::numeric, 1)          AS km2_repris,
       round((sum(ST_Area(ST_Difference(o.ancien, d.pris)))
              / 1e6)::numeric, 3)                               AS km2_reliquat,
       round((100 * sum(ST_Area(ST_Difference(o.ancien, d.pris)))
              / nullif(sum(ST_Area(o.ancien)), 0))::numeric, 2) AS pct
FROM   d JOIN o ON o.mere_id = d.mere_id AND o.an_reprise = d.an_reprise;

\echo ''
\echo '=== 4. Les fratries où il reste du sol sans propriétaire, nommées ======='
\echo '    Attendu : AUCUNE ligne, le § 3 devant valoir zéro.'
\echo '    ANOMALIE NON EXPLIQUÉE, à surveiller : le 5 septembre, avec la'
\echo '    mosaïque nue, cette section n''a rendu aucune ligne alors que le § 3'
\echo '    comptait 559 km² sur 429 fratries — soit 1,3 km² en moyenne, très'
\echo '    au-dessus du seuil d''affichage qui valait alors 0,01 km². Les deux'
\echo '    ne peuvent pas être vrais ensemble. Si le § 3 rend zéro et le § 4'
\echo '    rien, la question tombe ; sinon il faudra la reprendre.'
\echo ''

WITH d AS (
    SELECT v.mere_id, v.an_reprise, max(v.fratrie) AS fratrie,
           count(*)                                AS n_servies,
           ST_UnaryUnion(ST_Collect(v.geom))       AS pris
    FROM   partition_reprise(:'date'::date, NULL) v
    GROUP  BY v.mere_id, v.an_reprise
),
o AS (
    SELECT o.mere_id, o.an_reprise, count(*) AS n_ancien,
           ST_UnaryUnion(ST_Collect(o.geom)) AS ancien
    FROM   partition_reprise_morceau(:'date'::date, NULL) o
    GROUP  BY o.mere_id, o.an_reprise
)
SELECT coalesce(n.nom, '[' || a.insee_geofla || ']')           AS mere,
       d.an_reprise, d.fratrie, o.n_ancien, d.n_servies,
       round((ST_Area(ST_Difference(o.ancien, d.pris)) / 1e6)::numeric, 3)
                                                               AS km2_reliquat
FROM   d JOIN o ON o.mere_id = d.mere_id AND o.an_reprise = d.an_reprise
JOIN   atom a ON a.atom_id = d.mere_id
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
WHERE  ST_Area(ST_Difference(o.ancien, d.pris)) > 1e3
ORDER  BY 6 DESC
LIMIT  25;

\echo ''
\echo '--- Fin. La règle mosaïque est ADOPTÉE depuis le 5 septembre 2026 : elle'
\echo '    est `partition_reprise` dans `84`, et la carte la suit. Ce fichier'
\echo '    ne décide plus, il contrôle — les quatre sections doivent rendre ce'
\echo '    que l''en-tête annonce, à toute date où on les rejoue.'
\echo ''
\echo '    Après tout rejeu de `84`, la passe qui fait foi reste :'
\echo '      psql -d histgis -c "SELECT * FROM histgis.check_partition(''1870-12-01'');"'
\echo ''
