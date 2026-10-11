# Les tables analytiques du JO, 1941-1990 — 11 octobre 2026

## Ce qu'on a

- `JORF/tables/TABLE_ANALYTIQUE_JORF_1941…1990.pdf` : les 50 tables annuelles (4,4 Go),
  téléchargées depuis Légifrance (`/download/file/<id>/TB`).
- `jorf_txt/TABLE_ANALYTIQUE_JORF_AAAA_col.txt` : leur texte, colonnes séparées.

## Ce qu'on en tire

| fichier | quoi |
|---|---|
| `cantons/tables_jo.py` → `tables_jo_actes.csv` | tout ce que les tables disent des cantons : 567 lignes (275 rattachements de communes, 213 créations, 36 changements de nom…) |
| `cantons/rappel_tables.py` → `rappel_tables.csv` | contrôle : les actes connus par ailleurs (registre Légifrance + complément) que les tables retrouvent |
| `cantons/dater_par_tables.py` → `dates_par_tables_jo.csv` | les mouvements non datés de `mouvements_cantonaux.csv` cherchés dans les tables |
| `cantons/transferts_tables.py` → `transferts_tables_jo.csv`, `jo_page_date.csv` | les transferts datés, au format de `transferts_complement.csv`, avec la date de parution estimée par la page |

## Ce que valent les tables

Actes connus 1941-1990 retrouvés dans les tables : **263 sur 318**.

- créations et recompositions de cantons : **228 sur 233** ;
- les manquants sont surtout des « modifications de limites cantonales » de 1986-1990
  (55, dont 20 retrouvés) : ce sont des parties de territoire passées d'une commune à
  l'autre, que les tables classent sous « Circonscriptions administratives territoriales »,
  pas sous « Cantons ». Sans effet sur les communes entières.

Formes lues : articles « X au canton de Y (Dép.), p. N » ; listes « Création et modification
de cantons dans les départements suivants : Ain. — D. 82-77 du 25 janv. 1982, p. 371 » ;
rubriques « Cantons. — Essonne. Création et délimitation. — D. 67-589 » ; noms de
départements mal lus par l'OCR (« Sai'the », « Saône-et-Loife ») rapprochés à 82 %.

Limite : de 1941 à 1957 environ, la mise en colonnes mélange encore des lignes de deux
colonnes ; le département manque à 150 lignes. La recherche par commune
(`dater_par_tables.py`) ne s'en soucie pas : elle cherche dans le texte entier, nom approché.

## Les transferts isolés datés

Sur 274 transferts isolés sans date, **97** se retrouvent dans une table, chacun dans une
seule année ; contrôles justes (Saint-Couat 1951, Chambéon 1955, La Chapelle-Bertin 1962,
Salles-Mongiscard 1951, Crézières 1955, Belmont 1955). Après retrait des doublons et de ceux
déjà lus au JO : **93** dans `transferts_tables_jo.csv`, dont 53 avec la date du décret.

Date de parution (règle C : effet le lendemain) : estimée par la page. Pour une page, le
plus récent acte signé aux pages qui la précèdent, plus un jour. Contrôlé sur 236 actes
dont on connaît la date de parution : écart médian 1 jour, 229 à 7 jours au plus ; les
7 autres sont des numéros de page mal lus dans le contrôle, pas des erreurs de l'estimateur.

## Pose

`sql/110_pose_lecture_jo.sql` lit aussi `transferts_tables_jo.csv`, sous la
nature `transfert_table`. Même règle que les transferts lus au JO, une
différence : la table ne nomme pas le canton de départ ; la moitié gauche du
trou est posée au canton du bord gauche (fondement écrit dans `p110_qualite`).
Posé le 11 octobre 2026 : **142 périodes sur 73 communes** ; 20 tombent sur une
période déjà posée, et 110 s'en abstient.

`sql/111_corrige_transferts.sql` instruit ces 20 (et les 2 des transferts lus
au JO) : 13 communes gardées par la base dans leur canton de départ après
l'acte, 5 mises dans leur canton d'arrivée avant lui, 2 laissées (Orgerus,
Ferreux). Posé puis défait le 11 octobre pour éprouver le retour arrière ; à
rejouer avec `-v poser=on`.

Les deux sont dans `sql/rejouer_apres_rebuild.sh`, en dernier ; l'ordre de
rejeu est dans `sql/README.md`, « Qui dépend de qui », § 3.

## Ce qui reste

- 177 transferts isolés que les tables ne montrent pas (suivi : `RESTE_A_FAIRE.md` § 1 quater) : artefacts de la base, ou
  communes que l'OCR a trop abîmées. À trier.
- La preuve d'absence (« aucun acte dans ce département cette année-là ») : solide pour
  les créations et recompositions (98 %), moins pour les rattachements avant 1958.
