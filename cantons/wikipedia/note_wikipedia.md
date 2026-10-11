# Wikipédia, « Liste des cantons de … » — récolte du 10 octobre 2026

## Ce qui a été récolté

* **104 pages** « Liste des cantons de [département] » de fr.wikipedia (les 100
  départements hors Paris, plus Corse 1811-1975, Aisne 1973-2015, Loiret
  1806-1973 et 1982-2015), en wikitext brut par l'API `action=parse`, avec le
  `revid` de chaque page : `wikipedia_listes_cantons.json`.
* **10 pages complémentaires** vers lesquelles les listes renvoient : anciens
  cantons de l'Aveyron, de la Moselle, des Alpes-de-Haute-Provence, de
  Bourg-en-Bresse ; histoire du découpage cantonal de la Vendée et du Loiret ;
  Loiret 1790-1801 et 1801-1806 ; les pages de département *Seine-et-Oise* et
  *Seine* (gardées en brut, non extraites) : `wikipedia_cantons_complements.json`.
  `wikipedia_cantons_complements_2.json` est la même récolte avec une onzième
  page, *Liste des anciens cantons de la Vendée*, qu'aucun script ne lit ; il
  traînait à la racine du projet jusqu'au 11 octobre 2026.
* Les mêmes textes, une page par fichier : `wikitext/*.wiki` (3,3 Mo), pour grep.

Pas de page « liste des cantons » pour la Seine ni pour la Seine-et-Oise. Les
Pyrénées-Orientales redirigent vers *Histoire du découpage cantonal des
Pyrénées-Orientales*.

## Ce que les pages contiennent — et ne contiennent pas

Le plus souvent une liste à puces « année<ref>décret du … , JORF …</ref> : ce
qui change », sous une section du genre *Découpage cantonal de 1801 à 2014*.
Les références donnent presque toujours le **jour** du décret et la page du JO.

**Elles ne contiennent pas tous les changements.** Elles portent bien les
créations, scissions, suppressions, transferts de chef-lieu, et une partie des
transferts isolés de communes, mais pas tous : sur les **274 transferts
isolés** de `mouvements_cantonaux.csv`, Wikipédia en nomme **39**. Le reste
est vraisemblablement dans les articles « Canton de X » eux-mêmes, quand il
figure quelque part.

## Fichiers produits

| fichier | contenu |
|---|---|
| `changements_wikipedia.csv` | 1 475 puces datées, toutes années (1790-2014) |
| `changements_wikipedia_1940_1998.csv` | **731** d'entre elles, dont 639 datées au jour |
| `actes_wikipedia_vs_registre.csv` | 276 actes (département × jour) confrontés à `decrets_cantonaux.csv` |
| `dates_proposees_wikipedia.csv` | pour chaque mouvement non daté de `mouvements_cantonaux.csv`, les puces Wikipédia qui le nomment |

Colonnes de `changements_wikipedia*.csv` : `dep`, `page`, `revid`, `section`,
`ligne_wikitext` (pour retrouver la puce dans `wikitext/`), `date`,
`precision` (jour / mois / année), `nature` (mots-clés, indicatif),
`texte` (nettoyé), `references`, `cantons_lies`, `autres_liens`.

La date d'une puce se lit dans sa tête, puis dans son texte, puis dans ses
références ; une sous-puce hérite de la date de sa puce mère. Les sections
« composition actuelle », « redécoupage de 2014 », notes, bibliographie et les
tableaux sont écartés. Contrôle de complétude : une seule puce portant une
année 1940-1998 hors de ces sections a échappé à l'extraction (Vitrolles, 1991,
Bouches-du-Rhône — une ref coupée sur plusieurs lignes).

## Ce que la confrontation donne

**Au registre des actes** (`decrets_cantonaux.csv`, 343 actes 1958-1999) :
216 des 257 actes que Wikipédia date au jour à partir de 1958 y figurent (±3 jours,
signature ou publication). **41 n'y figurent pas** — dont la salve du
28 janvier 1964 (Valence, Angers, Marcq-en-Barœul, Lyon-XIII, Le Havre, Toulon),
Villeurbanne 1964, Strasbourg 1962, Chelles 1964, Abbeville 1963, Lens 1962,
Liévin 1975, Blagnac et Tournefeuille 1997, Le Poiré-sur-Vie 1975, les
renommages de Rennes et d'Auch-Sud-Est en 1985. Quelques-uns sont du bruit
(décisions du Conseil d'État, paragraphes d'introduction, une erreur de
Wikipédia : Reims-IX daté de 1985 pour 1982). **19 actes sont antérieurs à 1958**,
que le registre ne couvre pas : c'est la matière 1940-1957 qui manquait
(Saint-Sulpice 1949, Dompierre-sur-Chalaronne et Saint-Couat-du-Razès 1951,
Taponnat 1948, Rainsars 1946, Brive 1951, Sousceyrac 1949, Mérignac 1957…).

**Aux mouvements non datés** (`mouvements_cantonaux.csv`, 785 lignes sans
`date_retenue`) : 275 sont nommés par Wikipédia. Verdict par mouvement
(colonne `verdict`) :

| type | date_unique | dates_multiples | appariement_faible |
|---|---|---|---|
| transfert | 25 | 12 | 2 |
| partage | 64 | 96 | — |
| demembrement | 60 | 14 | 2 |

`date_unique` = une seule date parmi les puces qui nomment à la fois la commune
et un des cantons en jeu (ou la ville qui donne son nom au canton). **C'est une
proposition, pas un fait** : pour les villes partagées, la puce qui nomme la
ville peut être celle d'un autre redécoupage de la même ville (Montauban 1973
proposé là où le 6e canton date de 1991).

**Contrôle externe** : les quatre transferts déjà datés par Légifrance —
Laprade 1993-01-25, Vasselin 1993-01-27, Saint-Denis-des-Puits 1995-04-10,
Saint-Alban-de-Roche 1997-02-26 — sont retrouvés par Wikipédia **à la même
date, quatre fois sur quatre**.

## Refaire

La récolte passe par le navigateur (le proxy refuse fr.wikipedia.org en ligne
de commande) ; les trois scripts se rejouent sans réseau, depuis ce dossier :

    python3 extraire_wikipedia.py .
    python3 confronter_mouvements.py ../..
    python3 confronter_registre.py ../..

(`mwparserfromhell` requis : `pip install --user mwparserfromhell`.)

---

## Suite, 10 octobre au soir — les 60 actes absents du registre

**Tri** (`trier_actes_absents.py` → `actes_absents_tri.csv`) : 26 actes de
composition, 8 changements de département, 8 changements de nom ou de
chef-lieu, 3 annulations du Conseil d'État ; écartés : 5 déjà au registre sous
une autre date ou sans département (Toulouse 1997 daté du 16 au lieu du 26 par
Wikipédia, Reims-IX 1985 pour 1982, 82-82, 96-709, 64-847), 5 changements
d'arrondissement seul, 4 actes d'outre-mer, 1 paragraphe d'introduction.

**Pourquoi le moissonnage d'août les avait manqués.** Contre-épreuve faite sur
Légifrance par une seconde moisson, sur les titres « circonscriptions
administratives territoriales », « limites territoriales », etc. (473 titres) :
**tous** les actes cantonaux d'avant 2000 qu'elle renvoie sont déjà au registre,
sauf Liévin 1975 (titre sans le mot « cantons » au pluriel). Le registre est
donc complet **pour ce que Légifrance indexe**. Les actes trouvés par Wikipédia
sont ceux que Légifrance n'indexe pas du tout : ils n'existent que dans les JO
numérisés. *Wikipédia ne complète pas la moisson, elle complète le fonds.*

**Résultat** : `cantons/decrets_complement.csv`, 34 actes, chacun avec son
numéro de JO Légifrance (`JORF_AAAAMMJJ_NNN`), sa page, ses départements, les
codes INSEE des communes nommées, et `a_lire = oui`. Construit par
`batir_complement.py`.

**Pourquoi ce n'est pas versé dans `72`.** `75` date l'effet d'un acte par
`scrutin_cantonal`, qui commence en 1961 : un acte de 1946 y recevrait l'effet
du 4 juin 1961. Et un acte ajouté au registre raccourcit les reports de `79`.
D'où un diagnostic en lecture seule d'abord : `sql/diag_registre_complement.sql`.

**À télécharger** : `jo_a_telecharger.md`, 28 numéros du JO (le
téléchargement Légifrance est protégé, il se fait à la main). Gallica a les
mêmes JO pour 1946-1957, OCRisés, derrière une vérification anti-robot.
