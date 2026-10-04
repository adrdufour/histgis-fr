-- ============================================================================
-- histgis — 85_conflit_38_79.sql : rendre à `38` la fenêtre que `79` occupe
--
--     psql -d histgis -f sql/85_conflit_38_79.sql                 # INSTRUIT
--     psql -d histgis -v appliquer=1 -f sql/85_conflit_38_79.sql  # et corrige
--     psql -d histgis -v defaire=1   -f sql/85_conflit_38_79.sql  # défait
--
-- SANS `-v appliquer=1`, CE FICHIER NE MODIFIE RIEN.
--
-- ============================================================================
-- CE QUE LE PREMIER PASSAGE A TROUVÉ, LE 5 SEPTEMBRE 2026
-- ============================================================================
-- La première version de ce fichier tenait le refus de `38` pour un conflit de
-- bornes unique, portant sur six atomes. **Elle a refusé au premier essai, et
-- elle avait raison de refuser : les six atomes ne sont pas un problème mais
-- deux, et ils n'appellent pas le même geste.** Mesuré :
--
--   atome                     occupant                          canton  accord
--   ------------------------  --------------------------------  ------  ------
--   5260#0105 fraction        79  [1998-03-15, 1999-01-01)       0105    OUI
--   5260#0137 fraction        79  [1998-03-15, 1999-01-01)       0137    OUI
--   5260#0138 fraction        79  [1998-03-15, 1999-01-01)       0138    OUI
--   23054 Montagnat           75  [1985-03-10, 1992-03-22)       0139    non
--                             79  [1998-03-15, 1999-01-01)       0139    non
--   32737 Saint-Just          75  [1985-03-10, 1992-03-22)       0139    non
--                             79  [1998-03-15, 1999-01-01)       0139    non
--   31125 Saint-Denis-l.-B.   75  [1985-03-10, 1992-03-22)       0143    non
--                             79  [1998-03-15, 1999-01-01)       0143    non
--
-- (Le décret veut 0105 Bourg-Est pour Montagnat et Saint-Just, 0138 Bourg-Sud
-- pour Saint-Denis. La base dit 0139 Péronnas et 0143 Viriat — c'est-à-dire
-- les deux successeurs de **Bourg-Couronne**, le quatrième canton du décret,
-- celui qui n'a pas d'`unit_id`.)
--
-- ---------------------------------------------------------------------------
-- LES TROIS FRACTIONS : conflit de bornes, et rien d'autre.
-- ---------------------------------------------------------------------------
-- Un seul occupant, `79`, sur dix mois, et il désigne le MÊME canton que le
-- décret. Les deux sources disent la même chose sans la faire commencer à la
-- même date. `38` lit le texte primaire — décret n° 82-77 du 25 janvier 1982,
-- publié au JO le 26, transcrit dans `circo/bourg_en_bresse_1986_delimitations.md`
-- depuis `sources/modif_canton/JORF_19820126_21.pdf` — et couvre seize ans là
-- où le report en couvre dix mois. **Le texte fait foi** (`METHODE.md`), et
-- c'est ce que ce fichier libère.
--
-- ---------------------------------------------------------------------------
-- LES TROIS COMMUNES ENTIÈRES : ce n'est pas à `85` de trancher, ET CE N'EST
-- PROBABLEMENT PAS UN DÉSACCORD.
-- ---------------------------------------------------------------------------
-- La transcription du décret est sans ambiguïté. Bourg-Est « comprenant les
-- communes de Montagnat et Saint-Just » ; Bourg-Sud « comprenant la commune de
-- Saint-Denis-lès-Bourg » ; et Bourg-Couronne « comprenant les communes de
-- Péronnas, Buellas, Lent, Montcet, Montracol, Polliat,
-- Saint-André-sur-Vieux-Jonc, Saint-Rémy, Servas, Vandeins et Viriat » — les
-- trois communes litigieuses n'y sont PAS. Sur 1982, `38` a raison.
--
-- **Mais l'occupant de `75` ne parle pas de 1982.** Sa fenêtre
-- `[1985-03-10, 1992-03-22)` est bornée par deux scrutins cantonaux : c'est la
-- convention de date d'effet de `75` (§ 1, `scrutin_cantonal`), et elle place
-- l'acte qu'il a lu entre le scrutin de mars 1982 et celui de mars 1985 —
-- **après** le décret 82-77, dont l'effet conventionnel serait mars 1982.
--
-- Autrement dit : le registre connaît vraisemblablement un acte de 1982-1985
-- qui a déplacé ces trois communes de Bourg-Est et Bourg-Sud vers
-- Bourg-Couronne. Si c'est vrai, il n'y a aucun désaccord — il y a **une
-- fenêtre de `38` trop large** : son § 6 pose `[1982-01-26, 1999-01-01)` alors
-- que le décret ne vaut que jusqu'à l'acte suivant.
--
-- **`38` se taira de lui-même sur ces trois communes**, son § 6 n'insérant que
-- `WHERE NOT EXISTS` un chevauchement, et son § 7 lèvera le WARNING prévu pour
-- exactement ce cas. C'est le comportement voulu : *un fichier qui ne pose pas
-- ce qu'une meilleure source occupe déjà n'échoue pas, il cède.* Le § 3 bis
-- ci-dessous nomme l'acte de `75` pour que la question soit instruite, et non
-- pour la trancher ici.
--
-- ============================================================================
-- CE QUE CE FICHIER FAIT, EXACTEMENT
-- ============================================================================
-- Il retire les TROIS lignes que `79` a posées sur les TROIS FRACTIONS, avec
-- leur trace et leur ligne de qualité. Il ne touche à rien d'autre — ni aux
-- lignes de `75`, ni aux lignes de `79` sur les communes entières, qui sont
-- hors de son mandat.
--
-- ISSUE 1 OU ISSUE 2 ? La question posée par `ETAT.md` § 6 se dissout : `79`
-- n'écrit que là où la fenêtre est ENTIÈREMENT libre (son § 5, `p79_libre`),
-- or `38` posera `[1982-01-26, 1999-01-01)`, qui contient
-- `[1998-03-15, 1999-01-01)`. Un `79` rejoué après `38` s'abstiendrait de
-- lui-même sur ces trois fractions. Le retrait chirurgical et le rejeu complet
-- aboutissent donc au même état, et l'issue 1 coûte 36 296 lignes pour cela.
-- Le § 6 le VÉRIFIE au lieu de le supposer.
--
-- **LE VRAI CORRECTIF N'EST NI L'UN NI L'AUTRE : C'EST L'ORDRE.** Le conflit
-- n'existe que parce que `79` a été joué à la main, hors chaîne, après `38`.
-- Dans `sql/rejouer_apres_rebuild.sh`, `38` est déjà à sa place (ligne 233) et
-- `79` n'y figure pas encore. Tant que le script n'est pas complété jusqu'à
-- `83` avec `38` AVANT `79`, le prochain `rebuild.sh` refabriquera ce conflit.
--
-- *Un correctif qui ne change pas l'ordre qui a produit le défaut n'est pas un
-- correctif, c'est un entretien.*
--
-- Il ne joue pas `38` : ce fichier libère la fenêtre et s'arrête. `38` porte sa
-- propre trace et sa propre recette, et le lancer d'ici masquerait laquelle des
-- deux opérations a échoué. L'ordre est dit au § 7.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- ---------------------------------------------------------------------------
-- § 1. Garde-fous.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.p79_trace') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : p79_trace absente — 79 n''a jamais été joué, et il n''y a donc rien à libérer.';
    END IF;
    IF to_regclass('histgis.p79_qualite') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : p79_qualite absente. 79 a écrit sans sa table de qualité : ne rien retirer avant de savoir pourquoi.';
    END IF;
    IF to_regclass('histgis.p79_plancher') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : p79_plancher absente — le § 2 ne pourrait pas nommer l''acte qui fixe le plancher de l''Ain.';
    END IF;
    -- Prérequis du § 3 bis, et de lui seul : il interroge les trois tables de
    -- qualité des salves. Le dire ici plutôt que de laisser tomber une erreur
    -- de relation inconnue au milieu du fichier.
    IF to_regclass('histgis.p75_qualite') IS NULL
       OR to_regclass('histgis.p76_qualite') IS NULL
       OR to_regclass('histgis.p77_qualite') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : une des tables p75/p76/p77_qualite est absente — le § 3 bis ne pourrait pas nommer l''occupant des trois communes entières.';
    END IF;
END $$;

-- Les six atomes du décret 82-77, RANGÉS PAR PÉRIMÈTRE. La colonne `perimetre`
-- est ce qui a manqué à la première version de ce fichier : elle traitait les
-- six ensemble et refusait donc en bloc, alors que la moitié était libérable
-- et l'autre hors de son mandat.
DROP TABLE IF EXISTS t85_cible;
CREATE TEMP TABLE t85_cible AS
WITH par_atome(atom_id, unit_id, quoi) AS (
    VALUES ('5260#0105', '0105', 'Bourg-Est — fraction'),
           ('5260#0137', '0137', 'Bourg-Nord-Centre — fraction'),
           ('5260#0138', '0138', 'Bourg-Sud — fraction')
),
par_insee(insee, unit_id, quoi) AS (
    VALUES ('01254', '0105', 'Montagnat — commune entière'),
           ('01369', '0105', 'Saint-Just — commune entière'),
           ('01344', '0138', 'Saint-Denis-lès-Bourg — commune entière')
)
SELECT p.atom_id, p.unit_id AS unit_38, p.quoi, 'fraction'::text AS perimetre
FROM   par_atome p
UNION ALL
SELECT a.atom_id, i.unit_id, i.quoi, 'commune'::text
FROM   par_insee i
JOIN   atom a ON a.insee_geofla = i.insee AND NOT a.fraction;

CREATE INDEX ON t85_cible (atom_id);

\echo ''
\echo '=== 1. Les six atomes du décret, et leurs deux périmètres =============='
\echo ''

SELECT perimetre, quoi, atom_id, unit_38 FROM t85_cible
ORDER BY perimetre, quoi;

DO $$
DECLARE n int;
BEGIN
    SELECT count(*) INTO n FROM t85_cible;
    IF n <> 6 THEN
        RAISE EXCEPTION 'REFUS : % atome(s) trouvé(s) sur 6. Le décret 82-77 en vise six ; corriger la résolution avant de continuer.', n;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- § 2. QUI OCCUPE LA FENÊTRE, ET QUI L'Y A MIS.
--
--      La preuve ne se lit PAS dans la date `1998-03-15`, qui n'est qu'un
--      indice de forme — c'est aussi un scrutin cantonal, donc une borne
--      possible de `75` et de `76`. Elle se lit dans les traces.
--      *Une date qui a la bonne forme n'est pas une signature.*
--
--      `38` se reconnaît, lui, à SA date : `1982-01-26`. Interroger
--      `p38_trace` obligerait à la nommer dans la requête, et PostgreSQL
--      résout les noms de table au moment du plan : la requête échouerait
--      quand la table n'existe pas, c'est-à-dire dans le cas normal, avant que
--      `38` n'ait jamais tourné.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t85_occupant;
CREATE TEMP TABLE t85_occupant AS
SELECT c.perimetre, c.atom_id, c.unit_38, c.quoi,
       m.membership_id, m.unit_id, m.valid_from, m.valid_to,
       (m.unit_id = c.unit_38)                                       AS meme_canton,
       CASE
         WHEN m.valid_from = DATE '1982-01-26'                        THEN '38'
         WHEN EXISTS (SELECT 1 FROM p79_trace t
                       WHERE t.quoi = 'membership'
                         AND t.cle = m.membership_id::text)          THEN '79'
         ELSE 'autre'
       END                                                           AS pose_par
FROM   t85_cible c
JOIN   membership m ON m.atom_id = c.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(DATE '1982-01-26',
                                              DATE '1999-01-01', '[)');

CREATE INDEX ON t85_occupant (membership_id);

\echo ''
\echo '=== 2. Les occupants de la fenêtre 1982-1999 ==========================='
\echo ''

SELECT o.perimetre, o.quoi, o.unit_38 AS veut_38, o.unit_id AS occupe_par,
       daterange(o.valid_from, o.valid_to, '[)')                     AS sur,
       o.meme_canton, o.pose_par,
       q.sous_plafond, q.dernier_acte
FROM   t85_occupant o
LEFT   JOIN p79_qualite q ON q.membership_id = o.membership_id
ORDER  BY o.perimetre, o.quoi, o.valid_from;

\echo ''
\echo '    Le plancher de l''Ain, et l''acte qui le fixe :'
\echo ''

SELECT p.dep, p.plancher, p.dernier_acte, p.actes, p.actes_non_depouilles,
       (SELECT a.date_signature FROM acte_cantonal a
         WHERE a.legifrance_id = p.dernier_acte)          AS signe_le
FROM   p79_plancher p WHERE p.dep = '01';

-- ---------------------------------------------------------------------------
-- § 3. LE REFUS QUI PROTÈGE — et il ne porte QUE sur le périmètre à libérer.
--
--      La première version refusait dès qu'un occupant quelconque des six
--      atomes ne venait pas de `79`. Elle a donc refusé à cause des communes
--      entières, dont elle n'avait de toute façon rien à faire.
--      *Un contrôle dont le périmètre est plus large que l'action qu'il
--      protège transforme une information en blocage.*
--
--      Deux conditions, sur les trois fractions seulement :
--        (a) tout occupant vient de `79` — sinon `74`, `75`, `76` ou `77` sont
--            mieux renseignés que le report, et ce fichier n'a rien à leur
--            dire ;
--        (b) tout occupant désigne le MÊME canton que le décret — sinon ce
--            n'est plus un conflit de bornes mais un désaccord de fond, qui se
--            tranche sur pièces et jamais par un DELETE.
--
--      Les lignes déjà posées par `38` sont ignorées des deux contrôles : le
--      § 7 demande de relire ce fichier APRÈS `38`, et à ce moment-là c'est
--      `38` qui occupe. Un contrôle qui l'oublierait refuserait sa propre
--      relecture — et pire, un § 5 qui l'oublierait supprimerait le travail de
--      `38` en croyant libérer `79`.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3. Le tri des occupants, par périmètre ============================='
\echo ''

SELECT perimetre, pose_par, count(*) AS lignes,
       count(*) FILTER (WHERE meme_canton) AS dont_meme_canton
FROM   t85_occupant GROUP BY 1, 2 ORDER BY 1, 2;

DO $$
DECLARE etranger text; desaccord text; n79 int;
BEGIN
    SELECT string_agg(format('%s occupé par %s sur [%s,%s)',
                             atom_id, unit_id, valid_from, valid_to), ' ; ')
      INTO etranger FROM t85_occupant
     WHERE perimetre = 'fraction' AND pose_par = 'autre';
    IF etranger IS NOT NULL THEN
        RAISE EXCEPTION
          'REFUS : une fraction au moins est occupée par autre chose que 79 ou 38 : %', etranger
        USING HINT = 'Identifier le fichier qui l''a posée (diag_passages.sql) avant de rien retirer. Ce fichier ne sait libérer que 79.';
    END IF;

    SELECT string_agg(format('%s : le décret dit %s, l''occupant dit %s',
                             atom_id, unit_38, unit_id), ' ; ')
      INTO desaccord FROM t85_occupant
     WHERE perimetre = 'fraction' AND pose_par = '79' AND NOT meme_canton;
    IF desaccord IS NOT NULL THEN
        RAISE EXCEPTION
          'REFUS : DÉSACCORD DE FOND sur une fraction, pas de bornes : %', desaccord
        USING HINT = 'Le COG de 1999 et le décret de 1982 ne disent pas la même chose. Cela s''instruit sur pièces ; ce fichier n''en a pas le droit.';
    END IF;

    SELECT count(*) INTO n79 FROM t85_occupant
     WHERE perimetre = 'fraction' AND pose_par = '79';
    IF n79 = 0 THEN
        RAISE NOTICE 'Rien à libérer : aucune ligne de 79 sur les fractions. Si 38 est passé, lire le § 6.';
    ELSE
        RAISE NOTICE '% ligne(s) de 79 à libérer sur les fractions, toutes sur le canton du décret.', n79;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- § 3 bis. LES COMMUNES ENTIÈRES — instruites, jamais touchées.
--
--      Ce paragraphe n'agit pas. Il nomme l'acte que `75` invoque, pour que la
--      question « le décret de 1982 a-t-il été défait entre 1982 et 1985 ? »
--      se pose sur une pièce et non sur une intuition. Si `75` cite un acte
--      postérieur à janvier 1982, il n'y a pas de désaccord : il y a une
--      fenêtre de `38` trop large, et `38` cédera tout seul.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 3 bis. Les communes entières — sur quelle pièce repose l''occupant ?'
\echo '    LE PREMIER PASSAGE N''A RENDU QUE DES COLONNES VIDES : les lignes de'
\echo '    [1985-03-10, 1992-03-22) ne viennent PAS de 75, malgré des bornes'
\echo '    qui sont deux scrutins cantonaux. Or 76 emploie la MÊME convention'
\echo '    (« la longue traîne, sur la convention de 75 »), et 77 pose aussi'
\echo '    des transferts de commune entière. Les trois sont donc interrogées.'
\echo '    *Une convention de dates partagée par trois fichiers ne désigne'
\echo '    aucun des trois : elle ne fait que les rendre indiscernables.*'
\echo ''
\echo '    Un acte postérieur à janvier 1982 dissout le désaccord apparent et'
\echo '    rend 38 simplement trop large. Zéro ligne partout = l''occupant'
\echo '    vient d''ailleurs encore, et il faut passer par diag_passages.sql.'
\echo ''

SELECT o.quoi,
       daterange(o.valid_from, o.valid_to, '[)')                     AS sur,
       o.unit_id                                                     AS occupe_par,
       o.unit_38                                                     AS veut_38,
       s.fichier, s.canton_decret, s.n_actes, s.provenance, s.detail
FROM   t85_occupant o
LEFT   JOIN LATERAL (
       SELECT '75'::text AS fichier, q.canton_decret, q.n_actes::text AS n_actes,
              q.provenance, q.convention AS detail
         FROM p75_qualite q WHERE q.membership_id = o.membership_id
       UNION ALL
       SELECT '76', q.canton_decret, q.n_actes::text, q.provenance, q.convention
         FROM p76_qualite q WHERE q.membership_id = o.membership_id
       UNION ALL
       SELECT '77', q.commune, NULL, q.origine,
              CASE WHEN q.date_conventionnelle
                   THEN 'date conventionnelle, incertitude jusqu''au '
                        || coalesce(q.incertitude_jusqu_au::text, '?')
                   ELSE 'date INSEE — un fait' END
         FROM p77_qualite q WHERE q.membership_id = o.membership_id) s ON true
WHERE  o.perimetre = 'commune'
ORDER  BY o.quoi, o.valid_from;

\echo ''
\echo '    Si les trois se taisent encore, l''occupant vient d''un fichier que'
\echo '    ce paragraphe ne connaît pas. Ne pas l''ajouter ici au jugé :'
\echo '    `diag_passages.sql` tient l''inventaire des traces attendues, et'
\echo '    c''est lui qui doit répondre. Les candidats restants, dans l''ordre'
\echo '    de vraisemblance, sont 74 (Yvelines 1967) et 68 (jalon 1954).'

\echo ''
\echo '    Et la fenêtre RÉELLEMENT libre pour 38 sur chacune — c''est-à-dire'
\echo '    jusqu''où le décret de 1982 peut descendre sans écraser personne :'
\echo ''

SELECT c.quoi,
       DATE '1982-01-26'                                             AS depuis,
       coalesce(min(m.valid_from) FILTER (WHERE m.valid_from > DATE '1982-01-26'),
                DATE '1999-01-01')                                   AS jusqu_a,
       count(m.membership_id)                                        AS occupants
FROM   t85_cible c
LEFT   JOIN membership m ON m.atom_id = c.atom_id AND m.niveau = 'canton'
                        AND m.periode && daterange(DATE '1982-01-26',
                                                   DATE '1999-01-01', '[)')
WHERE  c.perimetre = 'commune'
GROUP  BY c.quoi
ORDER  BY c.quoi;

-- ---------------------------------------------------------------------------
-- § 4. Le retrait, sous `-v appliquer=1`.
--
--      TROIS TABLES, ET PAS UNE DE MOINS. `membership` porte l'état,
--      `p79_trace` porte le droit de le défaire, `p79_qualite` porte
--      l'inférence attachée à la ligne. Retirer la ligne sans sa trace
--      fabriquerait l'anomalie exacte que `diag_passages.sql` § 3 bis
--      cherche — une trace qui survit à ce qu'elle trace ; la retirer sans sa
--      qualité casserait la recette du § 10 c de `79`, qui exige une ligne de
--      qualité par ligne de trace.
-- ---------------------------------------------------------------------------
\if :{?appliquer}

BEGIN;

CREATE TABLE IF NOT EXISTS p85_trace (
    p85_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    atom_id    text        NOT NULL,
    unit_id    text        NOT NULL,
    niveau     text        NOT NULL,
    valid_from date        NOT NULL,
    valid_to   date        NOT NULL,
    qualite    jsonb,                 -- la ligne p79_qualite, entière
    retire_le  timestamptz NOT NULL DEFAULT now(),
    remis_le   timestamptz            -- non NULL = déjà défait
);

COMMENT ON TABLE p85_trace IS
    'Ce que 85 a retiré à 79 pour rendre aux trois fractions de Bourg la fenêtre 1982-1999. Garde de quoi tout remettre : les champs du rattachement et la ligne de qualité en jsonb.';

-- Les lignes à retirer, figées avant toute écriture : la suite les lit trois
-- fois, et une sous-requête relue après un DELETE ne rend plus la même chose.
--
-- LES DEUX CLAUSES DU `WHERE` SONT CRITIQUES, ET POUR DEUX RAISONS DIFFÉRENTES.
-- `pose_par = '79'` empêche une relecture après `38` de supprimer le travail
-- de `38`. `perimetre = 'fraction'` empêche de retirer à `79` les trois
-- communes entières, sur lesquelles il n'est pas en conflit de bornes mais en
-- désaccord de contenu — et un désaccord de contenu ne se règle pas en
-- effaçant l'une des deux réponses.
CREATE TEMP TABLE t85_retrait ON COMMIT DROP AS
SELECT o.membership_id, o.atom_id, o.unit_id, 'canton'::text AS niveau,
       o.valid_from, o.valid_to,
       -- `to_jsonb(q.*)` sur une jointure externe SANS correspondance ne rend
       -- PAS NULL : il rend un objet dont tous les champs valent null, et la
       -- recette ci-dessous ne verrait jamais l'absence qu'elle cherche.
       CASE WHEN q.membership_id IS NULL THEN NULL
            ELSE to_jsonb(q.*) END AS qualite
FROM   t85_occupant o
LEFT   JOIN p79_qualite q ON q.membership_id = o.membership_id
WHERE  o.perimetre = 'fraction'
  AND  o.pose_par  = '79';

INSERT INTO p85_trace (atom_id, unit_id, niveau, valid_from, valid_to, qualite)
SELECT atom_id, unit_id, niveau, valid_from, valid_to, qualite FROM t85_retrait;

DELETE FROM p79_qualite q USING t85_retrait r
 WHERE q.membership_id = r.membership_id;

DELETE FROM p79_trace t USING t85_retrait r
 WHERE t.quoi = 'membership' AND t.cle = r.membership_id::text;

DELETE FROM membership m USING t85_retrait r
 WHERE m.membership_id = r.membership_id;

COMMIT;

\echo ''
\echo '=== 4. Retiré ==========================================================='

SELECT count(*) AS lignes_retirees,
       count(*) FILTER (WHERE qualite IS NULL) AS sans_ligne_de_qualite
FROM   p85_trace WHERE remis_le IS NULL;

\echo ''
\echo '    Attendu : 3 et 0. Une ligne de 79 sans qualité serait une anomalie'
\echo '    de 79, à instruire avant d''aller plus loin.'

\else
\echo ''
\echo '=== 4. RIEN N''A ÉTÉ MODIFIÉ ============================================'
\echo '    Ce passage n''a fait qu''instruire. Pour libérer les trois fractions :'
\echo '      psql -d histgis -v appliquer=1 -f sql/85_conflit_38_79.sql'
\echo ''
\endif

-- ---------------------------------------------------------------------------
-- § 5. Contrôle collatéral — ce que le retrait ne devait PAS toucher.
--
--      Trois lignes retirées, et rien d'autre. Le compte des lignes de `79`
--      sur l'Ain le dit d'un chiffre : il doit baisser d'exactement 3.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 5. Ce que 79 garde dans l''Ain ======================================'
\echo ''

SELECT count(*)                                       AS lignes_79_dans_le_01,
       count(*) FILTER (WHERE q.fraction)             AS dont_fractions
FROM   p79_qualite q WHERE q.dep = '01';

-- ---------------------------------------------------------------------------
-- § 6. LA RECETTE — l'équivalence avec un rejeu complet de `79`, VÉRIFIÉE.
--
--      `fenetre_79_libre` rejoue le prédicat de `p79_libre` (§ 5 de `79`) sur
--      les six atomes. `false` sur les trois fractions APRÈS `38` signifie
--      qu'un `79` rejoué ne poserait rien pour elles : le retrait chirurgical
--      et le rejeu complet aboutissent au même état, et ce n'est plus une
--      déduction de lecture mais une mesure.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 6. Recette — à relire APRÈS avoir joué 38 =========================='
\echo ''

SELECT c.perimetre, c.quoi, c.unit_38,
       (SELECT m.unit_id FROM membership m
         WHERE m.atom_id = c.atom_id AND m.niveau = 'canton'
           AND m.periode @> DATE '1986-06-01')             AS canton_au_1er_juin_1986,
       (SELECT min(m.valid_from) FROM membership m
         WHERE m.atom_id = c.atom_id AND m.niveau = 'canton'
           AND m.periode && daterange(DATE '1982-01-26', DATE '1999-01-01', '[)'))
                                                           AS debut_le_plus_ancien,
       NOT EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = c.atom_id AND m.niveau = 'canton'
                      AND m.periode && daterange(DATE '1998-03-15',
                                                 DATE '1999-01-01', '[)'))
                                                           AS fenetre_79_libre
FROM   t85_cible c
ORDER  BY c.perimetre, c.quoi;

\echo ''
\echo '    Sur les FRACTIONS :'
\echo '      après 85 seul  : canton_au_1er_juin_1986 vide, fenetre_79_libre = t'
\echo '      après 38       : canton = unit_38, début = 1982-01-26, libre = f'
\echo '    Sur les COMMUNES : inchangé aux deux passages. C''est voulu.'

-- ---------------------------------------------------------------------------
-- § 7. La suite, dans cet ordre.
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 7. La suite ========================================================'
\echo ''
\echo '    psql -d histgis -v appliquer=1 -f sql/85_conflit_38_79.sql'
\echo '    psql -d histgis                -f sql/38_decret_1982_ain.sql   # SANS -1'
\echo '    psql -d histgis                -f sql/85_conflit_38_79.sql     # relire le § 6'
\echo ''
\echo '    ATTENDU DE 38, ET CE N''EST PAS 3/3/3 :'
\echo '      membership_remontee ... 3   les trois fractions'
\echo '      unit_version .......... 3   les trois noms de 1982'
\echo '      membership ............ 0   les trois communes restent occupées'
\echo '    et un WARNING « 0 rattachement(s) sur 3 pose(s) ». **C''est le bon'
\echo '    résultat**, pas un échec : 38 cède devant 75 sur les communes'
\echo '    entières, et le § 3 bis dit sur quelle pièce.'

-- ---------------------------------------------------------------------------
-- § 8. DÉFAIRE, sous `-v defaire=1`.
--
--      Remet les lignes de `79` telles qu'elles étaient. Le `membership_id`
--      change — il est `GENERATED ALWAYS AS IDENTITY` — donc la trace et la
--      qualité sont réécrites sur le NOUVEL identifiant, seule façon de les
--      garder cohérentes.
--
--      À NE FAIRE QUE SI `38` N'A PAS ÉTÉ JOUÉ DEPUIS : sa remontée occupe la
--      fenêtre, et la réinsertion heurterait la contrainte EXCLUDE.
-- ---------------------------------------------------------------------------
\if :{?defaire}

-- Hors transaction, et AVANT tout : psql planifie une instruction à la fois,
-- donc lever ici sous `ON_ERROR_STOP` arrête le script avant que les
-- instructions suivantes n'aient à résoudre le nom `p85_trace`.
DO $$
BEGIN
    IF to_regclass('histgis.p85_trace') IS NULL THEN
        RAISE EXCEPTION 'RIEN À DÉFAIRE : p85_trace n''existe pas — ce fichier n''a jamais été appliqué.';
    END IF;
END $$;

BEGIN;

DO $$
DECLARE bloquant text;
BEGIN
    SELECT string_agg(format('%s occupé par %s sur %s', m.atom_id, m.unit_id, m.periode), ' ; ')
      INTO bloquant
      FROM p85_trace p
      JOIN membership m ON m.atom_id = p.atom_id AND m.niveau = p.niveau
                       AND m.periode && daterange(p.valid_from, p.valid_to, '[)')
     WHERE p.remis_le IS NULL;
    IF bloquant IS NOT NULL THEN
        RAISE EXCEPTION 'REMISE IMPOSSIBLE — la fenêtre est reprise : %', bloquant
        USING HINT = 'Défaire 38 d''abord (son § 2), puis relancer avec -v defaire=1.';
    END IF;
END $$;

WITH remis AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT p.atom_id, p.unit_id, p.niveau, p.valid_from, p.valid_to
      FROM p85_trace p WHERE p.remis_le IS NULL
    RETURNING membership_id, atom_id, valid_from
),
tr AS (
    INSERT INTO p79_trace (quoi, cle)
    SELECT 'membership', membership_id::text FROM remis
    RETURNING cle
)
-- `jsonb_populate_record`, et surtout pas `(jsonb).*` : un jsonb ne s'étale
-- pas en colonnes par un astérisque. Le premier argument `NULL::p79_qualite`
-- ne sert qu'à donner le TYPE de la ligne à fabriquer.
INSERT INTO p79_qualite
SELECT (jsonb_populate_record(
            NULL::p79_qualite,
            jsonb_set(p.qualite, '{membership_id}',
                      to_jsonb(r.membership_id)))).*
  FROM p85_trace p
  JOIN remis r ON r.atom_id = p.atom_id AND r.valid_from = p.valid_from
 WHERE p.remis_le IS NULL AND p.qualite IS NOT NULL;

UPDATE p85_trace SET remis_le = now() WHERE remis_le IS NULL;

COMMIT;

\echo ''
\echo '=== 8. Remis à 79 ======================================================'
SELECT count(*) AS lignes_remises FROM p85_trace WHERE remis_le IS NOT NULL;

\endif

-- ============================================================================
-- § 9. CE QUI RESTE OUVERT, ET QU'IL NE FAUT PAS CROIRE RÉGLÉ
--
--   1. **L'ORDRE DANS LA CHAÎNE — c'est le seul correctif durable.**
--      Quand `rejouer_apres_rebuild.sh` sera complété jusqu'à `83` (point 2 de
--      `RESTE_A_FAIRE.md`), **`38` doit venir AVANT `79`** — il y est déjà, à
--      sa ligne 233. Alors `79` cédera de lui-même et ce fichier deviendra
--      inutile, ce qui est la meilleure chose qui puisse lui arriver.
--
--   2. **LA FENÊTRE DE `38` § 6 EST TROP LARGE, ET CE FICHIER NE LA CORRIGE
--      PAS.** Le décret de 1982 y rattache trois communes entières jusqu'en
--      1999, alors que `75` porte une composition de 1985 qui les place
--      ailleurs. Si l'acte lu par `75` est bien postérieur à janvier 1982 — ce
--      que le § 3 bis affiche —, la bonne borne haute de `38` est la date
--      d'effet de cet acte, et non `1999-01-01`. Corriger `38` en passant,
--      pendant qu'on le débloque, mêlerait deux gestes dans un même commit.
--
--   3. **`38` RETIRE DE LA COUVERTURE AVANT D'EN RENDRE.** Entre le § 4 et le
--      passage de `38`, les trois fractions n'ont plus de canton sur
--      1998-1999. Ne pas s'arrêter au milieu, et ne pas exporter la carte
--      entre les deux.
--
--   4. **BOURG-COURONNE ET LE TROU 1941-1982 RESTENT ENTIERS.** Le quatrième
--      canton du décret n'a aucun `unit_id` ; la base ne connaît que ses deux
--      successeurs de 1999, `0139` Péronnas et `0143` Viriat — qui sont
--      précisément les occupants des trois communes entières. Les combler
--      suppose de créer des unités, donc une décision de nomenclature qui
--      n'est pas dans les données.
--
--   5. **LE PÉRIMÈTRE DU § 3 DE `38` RESTE ÉTROIT.** Il ne contrôle que les
--      trois fractions, alors que son § 6 écrit sur trois communes de plus.
--      C'est pour cela qu'il a REFUSÉ sur les unes et se serait TU sur les
--      autres. Lui faire couvrir les six ferait qu'un prochain refus dise
--      toute la vérité du premier coup.
-- ============================================================================

\echo ''
\echo '85_conflit_38_79.sql — fin.'
\echo ''
