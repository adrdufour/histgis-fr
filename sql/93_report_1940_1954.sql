-- ============================================================================
-- histgis — 93_report_1940_1954.sql : les treize ans que personne n'occupait
--
--   psql -d histgis -1 -f sql/93_report_1940_1954.sql
--
-- ÉCRIT DANS `membership`. Tout est tracé dans `p93_trace` et le § 2 défait le
-- passage précédent : le fichier est rejouable seul.
--
-- CE QU'IL COMBLE
-- ===============
-- [1941-01-01, 1954-01-01) — le dernier vide franc de la couche cantonale.
-- Après `81`, plus aucune date entre 1954 et 1999 ne renvoie le néant ; sous
-- 1954 il restait treize années où `snapshot` ne rend rien du tout.
--
-- POURQUOI CE N'EST PAS UN TROISIÈME `79`
-- =======================================
-- `79` et `81` infèrent depuis une ABSENCE : le registre des actes ne connaît
-- rien dans l'intervalle, donc rien n'a bougé. L'affirmation est réfutable et
-- elle a été éprouvée (94,9 % contre 33,5 %, 49 départements sur 49), mais elle
-- repose sur la complétude d'un registre.
--
-- **Ici les deux bouts sont attestés.** 1940 vient de TRF-GIS, 1954 d'un
-- recensement, et les deux lectures n'ont aucune source commune. Le fichier ne
-- pose donc pas « rien n'a bougé parce que je n'ai pas d'acte » mais **« les
-- deux relevés disent le même canton »**. Un atome dont les deux bouts
-- divergent n'est pas posé — il n'est pas arbitré, il est laissé vide.
--
-- Le registre ne sert qu'à EXPLIQUER les désaccords qu'il prédit (§ 5), jamais
-- à autoriser le report. C'est l'inverse du rôle qu'il joue dans `79` et `81`.
--
-- CE QUE LA MESURE DIT, ET CE QU'ELLE NE DIT PAS
-- ==============================================
-- `70`, lecture seule, a mesuré cet intervalle et lui seul :
--
--   accord par commune, brut                            98,78 %
--   purgé des lectures géographiquement absurdes (`71`)  99,50 %
--   paires de communes conservées                       97,87 %
--   *témoin* 1954 → 1968, même mesure                   89,80 %
--
-- Trois créations en quatorze ans ici, trente là. **La divergence est portée
-- par les créations datées**, presque proportionnellement — donc par les
-- décrets, donc par ce que le registre sait nommer.
--
-- Ce que l'accord des deux bouts NE VOIT PAS, et qu'aucune requête ne verra :
-- une commune partie au canton voisin puis revenue avant 1954. `70` en donne la
-- borne haute — **76 transferts non datés probables sur 26 544 communes en
-- quatorze ans, 0,29 %** — et c'est une borne haute au sens strict, une lecture
-- OCR fausse tombant sur un canton voisin y étant indiscernable d'un vrai
-- mouvement.
--
-- LA VALEUR POSÉE VIENT DE 1940 SEUL ; 1954 NE FAIT QUE FILTRER
-- =============================================================
-- Conséquence, et elle désamorce le piège de circularité de `70` § 2 : la
-- classe `ferme_canton` de `c54_qualite` a été appariée **parce que** son canton
-- de 1954 concordait avec celui de 1940. L'inclure dans une MESURE ferait
-- mesurer au banc sa propre entrée. Mais ici, l'accord ne fournit aucune
-- valeur : il autorise seulement à poser le canton de 1940. Une ligne de cette
-- classe n'est donc pas fausse, elle est **non filtrée** — elle vaut exactement
-- ce que vaudrait un report à la `79`, sans le contrôle par l'autre bout.
--
-- La distinction voyage dans `p93_qualite.appariement`. Pour ne garder que ce
-- qui est réellement contrôlé aux deux bouts :
--
--   ... JOIN p93_qualite q USING (membership_id) WHERE q.appariement = 'ferme'
--
-- CE QUI N'EST PAS POSÉ, ET C'EST VOULU
-- =====================================
--   * les DÉSACCORDS. `71` a montré que 191 des 323 pointent vers un canton à
--     plus de cinq kilomètres — des lectures fausses, pas des transferts. Les
--     trancher demanderait la géométrie et un arbitrage par cas ; le fichier
--     préfère un trou déclaré à un rattachement arbitré en silence.
--   * les atomes ABSENTS du relevé de 1954. Le fascicule est dépouillé à
--     95,9 %, et une commune fusionnée entre 1941 et 1953 n'y a plus de ligne
--     par construction. Sans second bout, il n'y a rien à confronter.
--   * les FRACTIONS. Leur identifiant porte le canton (`atome#canton`), donc
--     deux fractions d'une même commune ne se rapprochent jamais d'un bout à
--     l'autre. 1940 en compte 333, le relevé de 1954 huit : le contrôle n'est
--     pas disponible, et poser sans lui reviendrait à faire confiance à 1940
--     seul précisément là où la situation est la plus instable — une commune
--     partagée entre deux cantons.
--
-- LES TROIS DÉCRETS, ET POURQUOI LEUR MOITIÉ BASSE EST UN FAIT
-- ============================================================
-- Gaudillère (annexe VII), le tableau A du recensement de 1954 et la lecture
-- aveugle des tableaux de population s'accordent sur TROIS créations entre 1940
-- et 1954, et sur trois seulement. Leurs treize communes sont dans
-- `c67_attendu` (`67_cantons_1949_1951.sql`) :
--
--   4630  Sousceyrac   D. 5.9.1949    4 communes  (Latronquière, Bretenoux, St-Céré)
--   0631  Tende        D. 10.9.1951   2 communes  (aucun atome avant 1947)
--   1930  Brive-Sud    D. 13.9.1951   7 communes  (dédoublement de Brive)
--
-- Ces treize-là DOIVENT être en désaccord entre les deux bouts, et le § 4 les
-- écarte comme les autres. Le § 5 leur rend leur moitié basse :
-- **[1941-01-01, signature)**, au canton de 1940.
--
-- Ce n'est pas une convention, c'est ce que le décret dit de lui-même : le
-- canton n'existait pas avant d'être créé. La convention serait la moitié
-- HAUTE — [signature, 1954-01-01) —, qui demanderait une date d'effet, donc le
-- premier tour du renouvellement des conseils généraux qui suit (règle de
-- `75`). **`scrutin_cantonal` ne commence qu'en 1961** : la règle du dépôt ne
-- s'applique pas ici faute de table. Cette moitié n'est donc pas posée. Elle
-- vaut, selon le décret, de deux à quatre ans sur onze communes — le trou le
-- mieux borné de la base, et une ligne à ajouter à `scrutin_cantonal` suffirait
-- à le fermer.
--
-- *Une convention ne s'applique pas là où un fait est disponible, et pas non
-- plus là où la table qui la porte ne va pas.*
--
-- Prérequis : `01`-`07` (couche 1870-1940), `68` (jalon 1954, `c54_qualite`),
--             `67` (`c67_attendu`). Indifférent à `79` et `81`, qui ne
--             descendent jamais sous 1968 ; le § 11 b le vérifie au lieu de le
--             supposer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set date_1940 '1940-06-01'
\set debut     '1941-01-01'
\set fin       '1954-01-01'
\set date_1954 '1954-06-01'

\echo ''
\echo '============================================================'
\echo ' 1941-1953 : LE REPORT ENTRE DEUX BOUTS ATTESTÉS'
\echo '============================================================'

-- ---------------------------------------------------------------------------
-- 1. Prérequis
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('histgis.c54_qualite') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/68_cog1954_membership.sql (jalon 1954, c54_qualite).';
    END IF;
    IF to_regclass('histgis.c67_attendu') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/67_cantons_1949_1951.sql (c67_attendu).';
    END IF;
    -- psql n'interpole PAS ses variables dans une chaîne dollar-quotée :
    -- les dates sont écrites en clair ici, et nulle part ailleurs.
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton' AND periode @> '1940-06-01'::date) THEN
        RAISE EXCEPTION 'PRÉREQUIS : la couche 1870-1940 est absente — jouer la chaîne 01-07.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM membership
                    WHERE niveau = 'canton' AND periode @> '1954-06-01'::date) THEN
        RAISE EXCEPTION 'PRÉREQUIS : le jalon 1954 est absent — jouer sql/68_cog1954_membership.sql.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. DÉFAIRE LE PASSAGE PRÉCÉDENT, ET PRENDRE LES TÉMOINS AVANT D'ÉCRIRE
--
-- `p93_trace` ne porte que des `membership_id` posés par ce fichier.
--
-- Les témoins sont pris ICI, dans la base, jamais recopiés d'un document.
-- ***Une recette qui compare à un nombre venu d'ailleurs mesure la mémoire de
-- celui qui l'a écrite, pas la base*** — `79` l'a payé de trois erreurs.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p93_trace (
    quoi text NOT NULL,
    cle  text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m
 USING p93_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;

TRUNCATE p93_trace;
DROP TABLE IF EXISTS p93_qualite;

DROP TABLE IF EXISTS p93_temoin;
CREATE TABLE p93_temoin AS
SELECT (SELECT count(*) FROM membership
         WHERE niveau = 'canton' AND periode @> '1940-06-01'::date) AS couche_1940,
       (SELECT count(*) FROM membership
         WHERE niveau = 'canton' AND periode @> '1954-06-01'::date) AS jalon_1954,
       (SELECT count(*) FROM membership
         WHERE niveau = 'canton' AND periode @> '1968-06-01'::date) AS jalon_1968,
       (SELECT count(*) FROM membership WHERE niveau = 'canton')    AS total_canton,
       (SELECT count(*) FROM membership WHERE niveau = 'circo')     AS total_circo;

\echo ''
\echo '-- 2. les témoins, pris avant toute écriture'
SELECT * FROM p93_temoin;

-- ---------------------------------------------------------------------------
-- 3. LES DEUX BOUTS, ATOME PAR ATOME
--
-- La clé est l'`atom_id` COMPLET, suffixe de fraction compris. Deux fractions
-- d'une même commune ne se rejoignent donc jamais, et c'est voulu : le § 4 les
-- compte à part plutôt que de les confondre avec la commune entière.
--
-- La contrainte `membership_non_chevauchant` garantit un canton au plus par
-- atome et par date : aucun `GROUP BY` n'est nécessaire, et un `count` le
-- vérifierait plutôt qu'il ne le corrigerait.
--
-- Le côté 1954 lit `membership`, pas `c54_qualite`, et joint la seconde en
-- LEFT : `87` a rendu au jalon quatre communes de la Seine qui n'ont pas de
-- ligne de qualité. *Lire la table de qualité au lieu de la donnée exclurait
-- en silence ce qu'un correctif ultérieur a ajouté.*
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p93_1940;
CREATE TABLE p93_1940 AS
SELECT m.atom_id,
       m.unit_id                AS canton_1940,
       m.valid_to               AS fin_1940,
       u.dep::text              AS dep,
       (m.atom_id LIKE '%#%')   AS fraction
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'date_1940'::date;

ALTER TABLE p93_1940 ADD PRIMARY KEY (atom_id);

DROP TABLE IF EXISTS p93_1954;
CREATE TABLE p93_1954 AS
SELECT m.atom_id,
       m.unit_id                          AS canton_1954,
       coalesce(q.appariement, 'hors_c54') AS appariement,
       q.insee
FROM   membership m
LEFT   JOIN c54_qualite q ON q.membership_id = m.membership_id
WHERE  m.niveau = 'canton'
  AND  m.periode @> :'date_1954'::date;

ALTER TABLE p93_1954 ADD PRIMARY KEY (atom_id);

\echo ''
\echo '-- 3. les deux bouts'
SELECT (SELECT count(*) FROM p93_1940)                          AS atomes_1940,
       (SELECT count(*) FROM p93_1940 WHERE fraction)           AS dont_fractions,
       (SELECT count(*) FROM p93_1954)                          AS atomes_1954,
       (SELECT count(*) FROM p93_1940 a JOIN p93_1954 b USING (atom_id))
                                                                AS communs;

-- ---------------------------------------------------------------------------
-- 4. LE VERDICT, ATOME PAR ATOME — et le tamis est nommé, pas subi
--
-- Cinq classes, exhaustives et disjointes. Elles se comptent avant qu'une
-- seule ligne soit écrite, et le § 11 h vérifie que leur somme est bien
-- l'effectif de 1940 : *un tamis dont les classes ne se rebouclent pas laisse
-- passer ce qu'on ne sait pas nommer.*
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p93_verdict;
CREATE TABLE p93_verdict AS
SELECT a.atom_id,
       a.canton_1940,
       b.canton_1954,
       a.dep,
       a.fraction,
       a.fin_1940,
       coalesce(b.appariement, '')  AS appariement,
       CASE WHEN a.fraction                THEN 'fraction'
            WHEN b.atom_id IS NULL         THEN 'absent_de_1954'
            WHEN a.fin_1940 <> :'debut'::date THEN 'serie_1940_ecourtee'
            WHEN a.canton_1940 = b.canton_1954 THEN 'accord'
            ELSE                                'desaccord'
       END                          AS verdict
FROM   p93_1940 a
LEFT   JOIN p93_1954 b ON b.atom_id = a.atom_id;

CREATE INDEX p93_verdict_idx ON p93_verdict (verdict, dep);

\echo ''
\echo '-- 4. le tamis, classe par classe'
SELECT verdict, count(*) AS atomes,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS pct
FROM   p93_verdict GROUP BY verdict ORDER BY atomes DESC;

\echo ''
\echo '   `accord` est le seul poste posé par le § 6.'
\echo ''
\echo '   ATTENTION AU DÉNOMINATEUR : la colonne `pct` ci-dessus rapporte'
\echo '   chaque classe à TOUS les atomes de 1940, y compris les 8 000 que le'
\echo '   relevé de 1954 ne porte pas. Le taux d''accord, lui, ne se lit que'
\echo '   sur les COMPARABLES — accord + désaccord —, et c''est le § 4 bis qui'
\echo '   le donne. Les deux ne sont pas du même ordre : 0,87 % de désaccord'
\echo '   ici vaut 1,11 % des comparables, et 98,78 % sur la seule classe'
\echo '   indépendante. Cette ligne annonçait « de l''ordre de 1,2 % » sans'
\echo '   dire de quoi, jusqu''au 6 septembre 2026.'
\echo ''
\echo '   ***Un taux sans son dénominateur est une opinion présentée comme une'
\echo '   mesure*** — cinquième fois dans ce dépôt, et la première où c''est le'
\echo '   commentaire et non la requête qui l''a commise.'
\echo ''
\echo '   Ce qu''il faut comparer est le § 4 bis, classe `ferme`, à `70` :'
\echo '   98,78 % sur 26 544 comparables. Si ces DEUX nombres ne sont pas'
\echo '   retrouvés à l''identique, `93` ne sélectionne pas la population que'
\echo '   `70` a mesurée, et son fondement tombe. `71` a montré que 191 des'
\echo '   323 désaccords pointent vers un canton à plus de cinq kilomètres —'
\echo '   des lectures fausses, pas des mouvements.'

\echo ''
\echo '-- 4 bis. l''accord selon la classe d''appariement de 1954'
\echo '   (`ferme` est la seule indépendante de 1940 ; `ferme_canton` a été'
\echo '    appariée PARCE QUE son canton concordait — son accord est vrai par'
\echo '    construction et ne mesure rien. Il ne FAUSSE rien non plus : la'
\echo '    valeur posée vient de 1940 seul.)'
SELECT appariement,
       count(*)                                                    AS atomes,
       count(*) FILTER (WHERE verdict = 'accord')                  AS accord,
       round(100.0 * count(*) FILTER (WHERE verdict = 'accord')
             / nullif(count(*) FILTER (WHERE verdict IN ('accord', 'desaccord')), 0), 2)
                                                                   AS pct
FROM   p93_verdict
WHERE  verdict IN ('accord', 'desaccord')
GROUP  BY appariement ORDER BY atomes DESC;

\echo ''
\echo '-- 4 ter. les vingt départements où l''accord est le plus bas'
\echo '   (à confronter à la dispersion connue du jalon : Belfort, Corse,'
\echo '    Moselle, Isère sont bas pour des raisons de LECTURE, pas de report)'
SELECT dep,
       count(*)                                   AS comparables,
       count(*) FILTER (WHERE verdict = 'accord') AS accord,
       round(100.0 * count(*) FILTER (WHERE verdict = 'accord')
             / nullif(count(*), 0), 1)            AS pct
FROM   p93_verdict WHERE verdict IN ('accord', 'desaccord')
GROUP  BY dep HAVING count(*) >= 20
ORDER  BY pct LIMIT 20;

-- ---------------------------------------------------------------------------
-- 5. LES TROIS DÉCRETS — leur moitié basse, et elle seule
--
-- La table est un RECUEIL DE PREUVES, pas une liste d'identifiants : chaque
-- ligne porte le décret qui la fonde. Les dates sont celles de `67`, elles-mêmes
-- établies par trois voies indépendantes (annexe VII de Gaudillère, tableau A
-- du recensement de 1954, lecture aveugle des tableaux de population).
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p93_decret;
CREATE TABLE p93_decret (canton_id text, signature date, source text);
INSERT INTO p93_decret VALUES
  ('4630', DATE '1949-09-05', 'D. 5.9.1949 — création de Sousceyrac (46)'),
  ('0631', DATE '1951-09-10', 'D. 10.9.1951 — création de Tende (06)'),
  ('1930', DATE '1951-09-13', 'D. 13.9.1951 — dédoublement de Brive (19)');

DROP TABLE IF EXISTS p93_borne_decret;
CREATE TABLE p93_borne_decret AS
SELECT v.atom_id,
       v.canton_1940,
       v.dep,
       d.signature,
       d.source,
       x.insee
FROM   c67_attendu x
JOIN   p93_decret  d ON d.canton_id = x.canton_id
JOIN   atom a        ON a.insee_geofla = x.insee AND NOT a.fraction
JOIN   p93_verdict v ON v.atom_id = a.atom_id
WHERE  v.verdict = 'desaccord';

\echo ''
\echo '-- 5. les treize communes des trois décrets, une par une'
SELECT x.canton_id, x.nom_canton, x.insee, x.nom,
       CASE WHEN b.atom_id IS NOT NULL THEN 'moitié basse posable jusqu''au ' || b.signature
            WHEN v.verdict = 'accord'  THEN 'ACCORD INATTENDU — à regarder'
            WHEN v.atom_id IS NOT NULL THEN 'classée ' || v.verdict
            ELSE                            'aucun atome en 1940 (attendu pour Tende)'
       END AS situation
FROM   c67_attendu x
LEFT   JOIN atom a        ON a.insee_geofla = x.insee AND NOT a.fraction
LEFT   JOIN p93_verdict v ON v.atom_id = a.atom_id
LEFT   JOIN p93_borne_decret b ON b.atom_id = a.atom_id
ORDER  BY x.canton_id, x.insee;

\echo ''
\echo '   Attendu : 11 moitiés basses (Sousceyrac 4, Brive-Sud 7) et 2 lignes'
\echo '   « aucun atome en 1940 » — Tende et La Brigue ne sont françaises que'
\echo '   depuis 1947 et n''ont aucun atome dans une trame qui part de 1870.'
\echo '   Un « ACCORD INATTENDU » voudrait dire que le canton de 1940 est déjà'
\echo '   celui de 1954 : ce serait le décret ou la lecture qui aurait tort,'
\echo '   pas le report — à instruire avant d''aller plus loin.'

-- ---------------------------------------------------------------------------
-- 6. CE QUI SERA POSÉ — et la fenêtre doit être ENTIÈREMENT libre
--
-- On ne pose pas dans les interstices : découper autour d'un occupant
-- fabriquerait des périodes que personne ne saurait relire. Rien n'est censé
-- occuper [1941, 1954) — `79` et `81` ne descendent pas sous 1968 — mais le
-- tamis reste en place, parce qu'une couche future n'aura pas à se souvenir de
-- ce fichier pour ne pas être écrasée.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS p93_pose;
CREATE TABLE p93_pose AS
SELECT v.atom_id,
       v.canton_1940                AS unit_id,
       v.dep,
       :'debut'::date               AS valid_from,
       :'fin'::date                 AS valid_to,
       'accord_deux_bouts'::text    AS fondement,
       v.appariement,
       NULL::date                   AS signature,
       NULL::text                   AS source
FROM   p93_verdict v
WHERE  v.verdict = 'accord'
UNION ALL
SELECT b.atom_id,
       b.canton_1940,
       b.dep,
       :'debut'::date,
       b.signature,
       'sous_decret',
       'ferme_hors_comparaison',
       b.signature,
       b.source
FROM   p93_borne_decret b;

DELETE FROM p93_pose WHERE valid_from >= valid_to;

DROP TABLE IF EXISTS p93_libre;
CREATE TABLE p93_libre AS
SELECT p.* FROM p93_pose p
WHERE  NOT EXISTS (
       SELECT 1 FROM membership m
       WHERE  m.atom_id = p.atom_id
         AND  m.niveau  = 'canton'
         AND  m.periode && daterange(p.valid_from, p.valid_to, '[)'));

\echo ''
\echo '-- 6. le tamis d''occupation'
SELECT (SELECT count(*) FROM p93_pose)  AS candidats,
       (SELECT count(*) FROM p93_libre) AS fenetre_libre,
       (SELECT count(*) FROM p93_pose) - (SELECT count(*) FROM p93_libre)
                                        AS ecartes_pour_occupation;

\echo ''
\echo '   qui occupe déjà ces fenêtres, s''il y a lieu'
SELECT coalesce(u.nom, m.unit_id) AS occupant,
       count(DISTINCT p.atom_id)  AS atomes,
       min(m.valid_from)          AS du,
       max(m.valid_to)            AS au
FROM   p93_pose p
JOIN   membership m ON m.atom_id = p.atom_id AND m.niveau = 'canton'
                   AND m.periode && daterange(p.valid_from, p.valid_to, '[)')
LEFT   JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
GROUP  BY 1 ORDER BY atomes DESC LIMIT 10;

-- ---------------------------------------------------------------------------
-- 7. GARDE-FOUS — avant d'écrire, pas après
-- ---------------------------------------------------------------------------
DO $$
DECLARE n bigint; ex text;
BEGIN
    SELECT count(*), min(atom_id) INTO n, ex FROM (
        SELECT atom_id FROM p93_libre GROUP BY atom_id HAVING count(*) > 1) q;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % atome(s) avec deux lignes (p. ex. %). Un atome ne peut être à la fois en accord et sous décret.', n, ex;
    END IF;

    SELECT count(*) INTO n FROM p93_libre WHERE valid_from < '1941-01-01'::date;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) mordent sur la couche 1870-1940.', n;
    END IF;

    SELECT count(*) INTO n FROM p93_libre WHERE valid_to > '1954-01-01'::date;
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) mordent sur le jalon de 1954.', n;
    END IF;

    SELECT count(*), min(p.atom_id) INTO n, ex FROM p93_libre p
     WHERE NOT EXISTS (SELECT 1 FROM unit u
                        WHERE u.unit_id = p.unit_id AND u.niveau = 'canton');
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % ligne(s) sur une unité absente (p. ex. %).', n, ex;
    END IF;

    -- une fraction ne doit jamais arriver jusqu'ici : le § 4 les a classées à
    -- part et le § 6 ne lit que `accord`. Le garde-fou dit si le classement a
    -- fui, pas si la règle est bonne.
    SELECT count(*) INTO n FROM p93_libre WHERE atom_id LIKE '%#%';
    IF n > 0 THEN
        RAISE EXCEPTION 'REFUS : % fraction(s) dans les lignes à poser.', n;
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 8. L'ÉCRITURE
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM p93_libre
    RETURNING membership_id
)
INSERT INTO p93_trace (quoi, cle)
SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '-- 8. posé'
SELECT count(*) AS rattachements FROM p93_trace WHERE quoi = 'membership';

-- ---------------------------------------------------------------------------
-- 9. LA QUALITÉ, LIGNE À LIGNE
--
-- Ce n'est pas de la documentation, c'est une colonne : une lecture qui ne
-- joint pas cette table prend un report pour un relevé.
--
--   fondement    'accord_deux_bouts' | 'sous_decret'
--   appariement  la classe de 1954 ; `ferme` seule est indépendante de 1940
--   chrono_trouee  la chronologie INSEE de la commune a un trou dans la
--                  fenêtre — signal, pas filtre : voir § 9 bis
-- ---------------------------------------------------------------------------
CREATE TABLE p93_qualite AS
SELECT m.membership_id,
       p.atom_id,
       p.unit_id,
       p.dep,
       p.fondement,
       p.appariement,
       (p.appariement = 'ferme')                         AS controle_independant,
       p.signature,
       p.source,
       round((p.valid_to - p.valid_from) / 365.25, 2)    AS annees_reportees,
       false                                             AS chrono_trouee
FROM   p93_libre p
JOIN   membership m ON m.atom_id    = p.atom_id
                   AND m.valid_from = p.valid_from
                   AND m.niveau     = 'canton';

ALTER TABLE p93_qualite ADD PRIMARY KEY (membership_id);
CREATE INDEX p93_qualite_dep_idx ON p93_qualite (dep, fondement);

-- La chronologie communale de l'INSEE ne commence qu'en 1943 : le drapeau ne
-- porte que sur [1943, 1954). Une commune absorbée puis rétablie dans la
-- fenêtre y laisse un trou, et la ligne posée l'ignore. C'est une RÉSERVE
-- déclarée, pas une correction : refermer un tel trou d'office est exactement
-- la faute commise sur Cherré.
-- `commune_moderne` est nommée dans une chaîne exécutée : une table absente
-- ferait échouer l'ANALYSE de la requête, garde ou pas — un `WHERE
-- to_regclass(...) IS NOT NULL` ne protège de rien, il est évalué trop tard.
DO $$
BEGIN
    IF to_regclass('histgis.commune_moderne') IS NULL THEN
        RAISE NOTICE 'commune_moderne absente (20/21 non joués) : chrono_trouee reste à false partout.';
        RETURN;
    END IF;
    EXECUTE $q$
        UPDATE p93_qualite q SET chrono_trouee = true
         WHERE EXISTS (
               SELECT 1 FROM commune_moderne c
               WHERE  c.atom_id = q.atom_id
                 AND  c.valid_to > '1943-01-01'::date
                 AND  c.valid_to < '1954-01-01'::date
                 AND  NOT EXISTS (SELECT 1 FROM commune_moderne d
                                   WHERE d.atom_id = q.atom_id
                                     AND d.valid_from <= c.valid_to
                                     AND d.valid_to   >  c.valid_to))
    $q$;
END $$;

\echo ''
\echo '-- 9. la qualité du report'
SELECT fondement,
       controle_independant,
       count(*)                        AS lignes,
       round(sum(annees_reportees))    AS atome_annees,
       round(avg(annees_reportees), 1) AS annees_moyennes
FROM   p93_qualite GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '-- 9 bis. les lignes dont la commune a un trou de chronologie INSEE'
\echo '   (réserve déclarée, aucune n''est retirée — la requête les nomme)'
SELECT count(*) AS lignes, count(DISTINCT dep) AS departements
FROM   p93_qualite WHERE chrono_trouee;

SELECT q.dep, q.atom_id, coalesce(u.nom, q.unit_id) AS canton
FROM   p93_qualite q
LEFT   JOIN unit u ON u.unit_id = q.unit_id AND u.niveau = 'canton'
WHERE  q.chrono_trouee ORDER BY q.dep, q.atom_id LIMIT 20;

\echo ''
\echo '   Pour ne garder que ce qui est contrôlé aux deux bouts et sans réserve :'
\echo '     ... JOIN p93_qualite q USING (membership_id)'
\echo '      WHERE q.controle_independant AND NOT q.chrono_trouee'

-- ---------------------------------------------------------------------------
-- 10. CE QUE LE TROU GARDE — la file d'attente, chiffrée par la base elle-même
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 10. ce qui reste vide en 1941-1953, et ce que ça coûte'
SELECT v.verdict,
       count(*)                                     AS atomes,
       round(count(*) * 13.0)                       AS atome_annees_perdues
FROM   p93_verdict v
WHERE  v.verdict <> 'accord'
  AND  NOT EXISTS (SELECT 1 FROM p93_borne_decret b WHERE b.atom_id = v.atom_id)
GROUP  BY 1 ORDER BY 2 DESC;

\echo ''
\echo '   Le poste le plus gros commande la suite. `absent_de_1954` se réduit'
\echo '   en achevant le dépouillement du fascicule (95,9 % aujourd''hui) ;'
\echo '   `desaccord` demande l''arbitrage géométrique de `71`, cas par cas ;'
\echo '   `fraction` demande une convention qui n''existe pas encore.'

-- ---------------------------------------------------------------------------
-- 11. RECETTES — elles doivent toutes valoir zéro, ou le nombre annoncé
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 11 a. un atome à deux cantons à la même date (doit valoir 0)'
SELECT count(*) AS atomes_a_deux_cantons FROM (
    SELECT m.atom_id, m.valid_from
    FROM   membership m WHERE m.niveau = 'canton'
    GROUP  BY 1, 2 HAVING count(DISTINCT m.unit_id) > 1) q;

\echo ''
\echo '-- 11 b. les couches existantes sont-elles intactes ? (écarts à 0)'
SELECT (SELECT count(*) FROM membership WHERE niveau = 'canton'
         AND periode @> '1940-06-01'::date) - t.couche_1940 AS ecart_1940,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
         AND periode @> '1954-06-01'::date) - t.jalon_1954  AS ecart_1954,
       (SELECT count(*) FROM membership WHERE niveau = 'canton'
         AND periode @> '1968-06-01'::date) - t.jalon_1968  AS ecart_1968,
       (SELECT count(*) FROM membership WHERE niveau = 'circo')
         - t.total_circo                                    AS ecart_circo
FROM   p93_temoin t;

\echo ''
\echo '-- 11 c. aucune ligne hors de la fenêtre (doit valoir 0)'
SELECT count(*) AS hors_bornes
FROM   p93_qualite q
JOIN   membership m ON m.membership_id = q.membership_id
WHERE  m.valid_from < :'debut'::date OR m.valid_to > :'fin'::date;

\echo ''
\echo '-- 11 d. toute ligne posée a-t-elle sa qualité ? (doit valoir 0)'
SELECT count(*) AS sans_qualite
FROM   p93_trace t
WHERE  t.quoi = 'membership'
  AND  NOT EXISTS (SELECT 1 FROM p93_qualite q
                    WHERE q.membership_id = t.cle::bigint);

\echo ''
\echo '-- 11 e. les lignes sous décret s''arrêtent-elles à la signature ? (0)'
SELECT count(*) AS mauvaise_borne
FROM   p93_qualite q
JOIN   membership m ON m.membership_id = q.membership_id
WHERE  q.fondement = 'sous_decret' AND m.valid_to <> q.signature;

\echo ''
\echo '-- 11 f. la jointure avec les deux couches voisines'
\echo '   (une ligne de 1940 finit le 1941-01-01, une ligne d''ici commence ce'
\echo '    jour-là et finit le 1954-01-01, où le jalon prend le relais : trois'
\echo '    lignes jointives, trois autorités distinctes, aucune fondue)'
SELECT count(*) FILTER (WHERE av.atom_id IS NOT NULL) AS jointes_a_1940,
       count(*) FILTER (WHERE ap.atom_id IS NOT NULL) AS jointes_a_1954,
       count(*)                                       AS lignes_posees
FROM   p93_qualite q
JOIN   membership m ON m.membership_id = q.membership_id
LEFT   JOIN membership av ON av.atom_id = q.atom_id AND av.niveau = 'canton'
                         AND av.valid_to = m.valid_from
LEFT   JOIN membership ap ON ap.atom_id = q.atom_id AND ap.niveau = 'canton'
                         AND ap.valid_from = m.valid_to;

\echo ''
\echo '   `jointes_a_1954` doit valoir le nombre de lignes `accord_deux_bouts`'
\echo '   et rien de plus : une ligne sous décret s''arrête à la signature et'
\echo '   laisse ouvert l''intervalle que le décret gouverne.'

\echo ''
\echo '-- 11 g. ce que snapshot répond désormais'
SELECT d::date AS a_la_date,
       (SELECT count(*) FROM membership m
         WHERE m.niveau = 'canton' AND m.periode @> d::date) AS rattachements
FROM   (VALUES ('1940-06-01'), ('1941-06-01'), ('1945-06-01'), ('1950-06-01'),
               ('1953-06-01'), ('1954-06-01'), ('1968-06-01')) v(d);

\echo ''
\echo '   1941 à 1953 doit passer de ZÉRO à l''effectif du § 8. 1940, 1954 et'
\echo '   1968 ne doivent PAS bouger : ce sont les témoins du § 11 b, relus ici'
\echo '   par un autre chemin.'

\echo ''
\echo '-- 11 h. le tamis se reboucle-t-il ? (l''écart doit valoir 0)'
SELECT (SELECT count(*) FROM p93_1940)                              AS atomes_1940,
       (SELECT count(*) FROM p93_verdict)                           AS classes,
       (SELECT count(*) FROM p93_1940) - (SELECT count(*) FROM p93_verdict)
                                                                    AS ecart;

ANALYZE membership; ANALYZE p93_qualite;

\echo ''
\echo '============================================================'
\echo ' Report posé. Pour ne garder que la part contrôlée aux deux'
\echo ' bouts par un appariement indépendant de 1940 :'
\echo ''
\echo '   DELETE FROM histgis.membership m USING histgis.p93_qualite q'
\echo '    WHERE q.membership_id = m.membership_id'
\echo '      AND NOT q.controle_independant;'
\echo ''
\echo ' Pour tout défaire : rejouer ce fichier, ou lancer le DELETE du § 2.'
\echo '============================================================'
