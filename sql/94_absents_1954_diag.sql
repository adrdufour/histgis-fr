-- ============================================================================
-- histgis — 94_absents_1954_diag.sql : les 7 970 que `93` n'a pas pu poser
--
--   psql -d histgis -f sql/94_absents_1954_diag.sql
--
-- LECTURE SEULE. N'écrit ni dans `atom` ni dans `membership`.
--
-- LA QUESTION
-- ===========
-- `93` a posé 29 686 rattachements sur 1941-1953 et refusé 8 618 atomes. Son
-- § 10 chiffre le refus : **7 970 atomes « absents du relevé de 1954 »,
-- 103 610 atome-années** — le quart de la fenêtre, et de très loin le premier
-- poste devant les fractions (4 225) et les désaccords (4 199).
--
-- « Absent du relevé de 1954 » recouvre DEUX choses que rien ne sépare pour
-- l'instant, et dont l'une n'est pas une perte :
--
--   * la commune **était morte** — absorbée entre 1941 et 1953. Elle n'a pas
--     de ligne en 1954 parce qu'elle n'existait plus. `93` ne lui donne rien,
--     alors qu'elle a vécu une partie de la fenêtre et que son canton de 1940
--     vaut jusqu'à sa mort. **C'est de la couverture à prendre.**
--   * la commune **vivait** et le fascicule ne l'a pas rendue — 161 pages
--     muettes, quatre départements absents, d'autres absorbés par leur voisin.
--     Là il n'y a rien à poser : le second bout manque, et le report perdrait
--     ce qui fait sa force.
--
-- ***Une classe de refus qui porte deux causes se traite comme la plus
-- mauvaise des deux tant qu'on ne l'a pas ouverte.*** C'est ce fichier.
--
-- LA RÉPONSE — joué le 6 septembre 2026
-- =====================================
--   vivante_en_1954        7 870   98,7 %
--   MORTE_DANS_LA_FENETRE     55    0,7 %   →  414 atome-années
--   jamais_dans_le_cog        45    0,6 %
--
-- **L'hypothèse qui a fait écrire ce fichier est réfutée.** La part posable
-- vaut **414 atome-années sur 103 610, soit 0,4 %** — un millième de ce que
-- `93` a posé. Il n'y a pas de § supplémentaire à écrire dans `93` : le jeu
-- n'en vaut pas la chandelle, et le dire est le résultat.
--
-- Les 55 sont pourtant réelles et bien datées — Brest-2, Brest-3, Douarnenez,
-- Concarneau meurent en 1945, Niederbronn en septembre 1945 : ce sont les
-- fusions d'après-guerre, et la classification les trouve. Elles sont peu
-- nombreuses parce que la vague de fusions est celle de 1971-1972, pas celle
-- des années 1940. *Un nombre historiquement plausible est un contrôle.*
--
-- CE QUE LE § 3 A TROUVÉ, ET QUI N'ÉTAIT PAS LA QUESTION POSÉE
-- ============================================================
-- La perte de lecture **ne se concentre pas** sur les six départements que
-- `note_1954.md` nomme : ils portent 491 des 7 870, soit **6,2 %**. Elle est
-- répartie sur presque tous les départements, entre 19 et 42 % de leurs
-- communes — Ariège 42,4 %, Haute-Saône 37,2 %, Jura 34,5 %.
--
-- Et le 52, donné « ABSENT » par la note, ne perd que 30,2 % de ses communes :
-- **la liste des quatre départements absents est périmée**, ils ont été repris
-- depuis.
--
-- C'est un défaut GÉNÉRAL du dépouillement, pas un lot de fascicules manquants.
-- Conséquence chiffrée au § 5.
--
-- *Le § 3 a été écrit pour confirmer une explication ; il l'a démentie. Une
-- recette qui ne peut que confirmer ne sert à rien — celle-ci disait d'avance
-- ce qu'un résultat uniforme signifierait, et c'est ce qui la rend lisible.*
--
-- CE QU'IL NE PEUT PAS DIRE
-- =========================
-- L'univers communal de l'INSEE commence en **1943**. Une commune morte entre
-- le 1er janvier 1941 et le 1er janvier 1943 n'y figure pas du tout, et se
-- confond ici avec « jamais dans le COG ». La classe existe et est comptée à
-- part ; elle n'est pas tranchée.
--
-- Et le piège de `cm_atome`, déjà payé par `59` : une commune disparue passe
-- par son SUCCESSEUR, donc deux communes fusionnées depuis partagent un atome.
-- Le test de mort porte donc sur `max(valid_to)` de TOUTES les lignes de
-- l'atome, jamais d'un code : un atome dont un seul des codes s'éteint n'est
-- pas mort, il a changé de nom.
--
-- Prérequis : `93` joué (`p93_verdict`), `20`/`21` joués (`commune_moderne`).
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set debut '1941-01-01'
\set fin   '1954-01-01'

\echo ''
\echo '============================================================'
\echo ' LES ABSENTS DE 1954 — morts ou non lus ?'
\echo '============================================================'

DO $$
BEGIN
    IF to_regclass('histgis.p93_verdict') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/93_report_1940_1954.sql (p93_verdict).';
    END IF;
    IF to_regclass('histgis.commune_moderne') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/20 et sql/21 (commune_moderne).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. La chronologie INSEE de chaque absent, ramenée à l'atome
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS d94_absent;
CREATE TABLE d94_absent AS
SELECT v.atom_id,
       v.dep,
       v.canton_1940,
       (SELECT min(c.valid_from) FROM commune_moderne c WHERE c.atom_id = v.atom_id)
                                                        AS cog_debut,
       (SELECT max(c.valid_to)   FROM commune_moderne c WHERE c.atom_id = v.atom_id)
                                                        AS cog_fin,
       (SELECT count(*)          FROM commune_moderne c WHERE c.atom_id = v.atom_id)
                                                        AS cog_lignes
FROM   p93_verdict v
WHERE  v.verdict = 'absent_de_1954';

CREATE INDEX d94_absent_idx ON d94_absent (dep);

ALTER TABLE d94_absent ADD COLUMN classe text;
UPDATE d94_absent SET classe =
  CASE WHEN cog_lignes = 0                     THEN 'jamais_dans_le_cog'
       WHEN cog_fin <= :'debut'::date          THEN 'morte_avant_1941'
       WHEN cog_fin <  :'fin'::date            THEN 'MORTE_DANS_LA_FENETRE'
       ELSE                                         'vivante_en_1954'
  END;

\echo ''
\echo '-- 1. les 7 970, ouverts en quatre'
SELECT classe,
       count(*)                                              AS atomes,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1)    AS pct
FROM   d94_absent GROUP BY classe ORDER BY atomes DESC;

\echo ''
\echo '   `MORTE_DANS_LA_FENETRE` est le gain : ces communes ont vécu une part'
\echo '   de 1941-1953 et leur canton de 1940 vaut jusqu''à leur mort. Elles ne'
\echo '   manquent pas au relevé de 1954, elles n''y ont pas leur place.'
\echo ''
\echo '   `vivante_en_1954` est la perte réelle : le second bout manque, donc'
\echo '   le contrôle qui fait la force de `93` n''est pas disponible. Rien à'
\echo '   poser sans changer de fondement.'
\echo ''
\echo '   `jamais_dans_le_cog` mêle les mortes de 1941-1942, invisibles à un'
\echo '   univers qui commence en 1943, et les atomes sans code moderne. Non'
\echo '   tranché — ne pas le compter comme un gain.'

-- ---------------------------------------------------------------------------
-- 2. CE QUE LA CLASSE POSABLE VAUT — en atome-années, pas en atomes
--
-- Un atome mort en 1942 rend deux ans, un mort en 1953 en rend douze. Compter
-- les atomes ferait croire à un gain uniforme qui n'existe pas.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 2. le gain, en atome-années'
SELECT count(*)                                                    AS atomes,
       round(sum((cog_fin - :'debut'::date) / 365.25))              AS atome_annees,
       round(avg((cog_fin - :'debut'::date) / 365.25), 1)           AS annees_moyennes,
       min(cog_fin)                                                AS mort_la_plus_tot,
       max(cog_fin)                                                AS mort_la_plus_tard
FROM   d94_absent WHERE classe = 'MORTE_DANS_LA_FENETRE';

\echo ''
\echo '   À comparer aux 103 610 atome-années que `93` § 10 impute en bloc à'
\echo '   la classe `absent_de_1954`. La part posable est celle-ci, et elle'
\echo '   seule.'

\echo ''
\echo '-- 2 bis. par année de mort — la forme de la courbe'
SELECT extract(year FROM cog_fin)::int AS annee_de_mort,
       count(*)                        AS atomes
FROM   d94_absent WHERE classe = 'MORTE_DANS_LA_FENETRE'
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '   Une année qui porte à elle seule l''essentiel des morts n''est pas'
\echo '   un fait historique, c''est une date par défaut : à instruire avant'
\echo '   d''en tirer une ligne de `membership`.'

-- ---------------------------------------------------------------------------
-- 3. LA PERTE DE LECTURE, PAR DÉPARTEMENT — et le contrôle qui la juge
--
-- `note_1954.md` nomme les départements que l'extraction a manqués : 43, 52,
-- 74, 87 absents, 67 absorbé dans 66, 17 dans 16. Si `vivante_en_1954` s'y
-- concentre, la classe est bien ce qu'on croit. Si elle est uniforme, c'est
-- autre chose, et il faut le savoir avant de dépouiller quoi que ce soit.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. les vingt départements les plus touchés par la perte de lecture'
SELECT a.dep,
       count(*) FILTER (WHERE a.classe = 'vivante_en_1954')        AS non_lues,
       (SELECT count(*) FROM p93_verdict v WHERE v.dep = a.dep)    AS atomes_1940,
       round(100.0 * count(*) FILTER (WHERE a.classe = 'vivante_en_1954')
             / nullif((SELECT count(*) FROM p93_verdict v WHERE v.dep = a.dep), 0), 1)
                                                                   AS pct_du_dep,
       CASE WHEN a.dep IN ('43','52','74','87') THEN 'annoncé ABSENT par note_1954'
            WHEN a.dep IN ('67','17')           THEN 'annoncé ABSORBÉ par son voisin'
            ELSE '' END                                            AS deja_connu
FROM   d94_absent a
GROUP  BY a.dep
ORDER  BY non_lues DESC LIMIT 20;

\echo ''
\echo '-- 3 bis. les six départements nommés par note_1954.md, tous ensemble'
\echo '   (s''ils ne sortent pas en tête du § 3, la note décrit un autre défaut'
\echo '    que celui que cette classe mesure)'
SELECT sum(CASE WHEN classe = 'vivante_en_1954' THEN 1 ELSE 0 END) AS non_lues,
       count(*)                                                    AS absents_en_tout
FROM   d94_absent WHERE dep IN ('43','52','74','87','67','17');

-- ---------------------------------------------------------------------------
-- 4. UN ÉCHANTILLON, pour que la classe ne reste pas un nombre
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4. vingt communes mortes dans la fenêtre, avec leur canton de 1940'
SELECT a.dep, a.atom_id, a.cog_fin AS morte_le,
       coalesce(u.nom, a.canton_1940) AS canton_de_1940
FROM   d94_absent a
LEFT   JOIN unit u ON u.unit_id = a.canton_1940 AND u.niveau = 'canton'
WHERE  a.classe = 'MORTE_DANS_LA_FENETRE'
ORDER  BY a.cog_fin, a.dep, a.atom_id LIMIT 20;

-- ---------------------------------------------------------------------------
-- 5. LA COUVERTURE RÉELLE DU JALON DE 1954 — et le dénominateur qui trompe
--
-- `ETAT.md` § 2.3 et `note_1954.md` annoncent **95,9 %** pour la lecture de
-- 1954. Le nombre est juste et il ne dit pas ce qu'on lui fait dire : c'est
-- 30 128 lignes sur 31 400, donc la part des lignes TRANSCRITES qui ont reçu un
-- code — la qualité de l'appariement, pas la couverture du pays. Les pages
-- muettes ne sont pas au dénominateur : elles n'ont produit aucune ligne.
--
-- La couverture, elle, se mesure contre les communes qui existaient. C'est ce
-- que fait ce paragraphe, et il tombe vingt points plus bas.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 5. ce que le jalon de 1954 couvre vraiment'
WITH b AS (
  SELECT count(*) FILTER (WHERE NOT fraction)                       AS atomes_1940,
         count(*) FILTER (WHERE verdict IN ('accord','desaccord'))  AS comparables,
         count(*) FILTER (WHERE verdict = 'absent_de_1954')         AS absents
  FROM   p93_verdict)
SELECT b.atomes_1940,
       b.comparables,
       (SELECT count(*) FROM d94_absent WHERE classe = 'vivante_en_1954')
                                                                    AS vivantes_non_lues,
       round(100.0 * b.comparables / nullif(b.atomes_1940, 0), 1)   AS pct_couvert,
       round((SELECT count(*) FROM d94_absent WHERE classe = 'vivante_en_1954') * 13.0)
                                                                    AS atome_annees_en_jeu
FROM   b;

\echo ''
\echo '   `pct_couvert` est la couverture du jalon sur les communes vivantes en'
\echo '   1940. Le 95,9 % des documents est une AUTRE mesure, sur un autre'
\echo '   dénominateur, et les deux ne se remplacent pas.'
\echo ''
\echo '   ***Un taux sans son dénominateur est une opinion présentée comme une'
\echo '   mesure*** — et celui-ci était rassurant depuis le 14 août 2026.'
\echo ''
\echo '   `atome_annees_en_jeu` est ce que rendrait l''achèvement du'
\echo '   dépouillement SUR LA SEULE FENÊTRE 1941-1953. Il faut y ajouter le'
\echo '   jalon de 1954 lui-même, et tout ce qui s''y appuie en aval — le report'
\echo '   vers 1962 quand ce jalon existera. Le dépouillement de 1954 n''est pas'
\echo '   une dette de finition : c''est le premier levier de toute la période.'

\echo ''
\echo '============================================================'
\echo ' Rien n''a été écrit dans le modèle.'
\echo ''
\echo ' VERDICT DU 6 SEPTEMBRE 2026 : `MORTE_DANS_LA_FENETRE` vaut 55'
\echo ' atomes et 414 atome-années — 0,4 % de la classe. **Il n''y a'
\echo ' PAS de § supplémentaire à écrire dans `93`**, et c''est le'
\echo ' résultat de ce fichier. Le refus était bien ce qu''il disait'
\echo ' être : une perte de lecture, à 98,7 %.'
\echo ''
\echo ' Ce qui reste après ce fichier est au § 5, et ce n''est pas'
\echo ' 1941-1953 : c''est le dépouillement de 1954 lui-même.'
\echo '============================================================'
