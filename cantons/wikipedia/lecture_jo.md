# Lecture des JO du complément — 11 octobre 2026

28 numéros du JO déposés dans `sources/JORF/` par Adrien, convertis en texte
(`pdftotext -layout`, puis `jorf_colonnes.py`) : `jorf_txt/<nom>.txt` et
`<nom>_col.txt`. Tous ont une couche texte, y compris ceux de 1946-1951.

## Ce que la lecture a ajouté à Wikipédia

| trouvé au JO | où | absent de Wikipédia parce que |
|---|---|---|
| **Seine-et-Oise, 28 janvier 1964** : seize articles, une trentaine de cantons créés ou recomposés, Méry-sur-Oise et Butry-sur-Oise échangés, Achères passée de Maisons-Laffitte à Saint-Germain | `JORF_19640130_25`, p. 1090-1092 | Wikipédia n'a pas de liste des cantons de Seine-et-Oise |
| **Corse, tableau annexé à la loi 75-356** : les 360 communes, canton par canton, au 15 mai 1975 | `JORF_19750516_113` | la page Corse ne donne que les créations |
| Salles-Mongiscard : Salies -> Orthez (14 novembre 1951) | `JORF_19511117_272`, p. 11415 | non cité |
| La Chapelle-Bertin : Paulhaguet -> Allègre (22 janvier 1962) | `JORF_19620127_22`, p. 918 | non cité |
| Pas-de-Calais : c'est le **n° 62-5** (et non le 62-6) qui répartit Carvin, Houdain, Lens, Liévin en neuf cantons | `JORF_19620111_8`, p. 316 | Wikipédia cite le 62-6, qui ne crée que les arrondissements |
| Lens 1949 : Lens-Ouest devient canton de **Liévin** ; Saumur 1963 : chef-lieu de Saumur-Nord-Est à Allonnes, Saumur-Nord-Ouest devient Saumur-Nord ; Liévin 1975 : Liévin-Nord-Ouest devient **Bully-les-Mines** | | renommages non cités |

## Ce que la lecture corrige

* Mérignac : le texte dit « décret en date du **21** septembre 1957 », le titre
  et le sommaire « 24 septembre ». Le décret n'érige que le chef-lieu, sans
  composition.
* Mauléon 1965 : c'est un arrêté de **fusion de communes** (Châtillon-sur-Sèvre
  + Saint-Jouin-sous-Châtillon), pas un acte cantonal.
* Les clauses d'effet : aucun des textes de 1946-1964 ne fixe de date d'effet ;
  ils s'appliquent « avec toutes les conséquences qu'ils comportent ».

## Fichiers

* `cantons/composition_complement.csv` — 369 lignes, 73 cantons (extraction
  automatique corrigée + transcriptions à la main) ;
* `cantons/transferts_complement.csv` — 13 communes changées de canton ;
* `cantons/corse_1975.csv` — 360 communes, 41 cantons, 360 codes INSEE
  distincts, tous appariés ;
* `sql/diag_lecture_jo.sql` — la confrontation avec la base, en lecture seule.

Produits par `composition_complement.py` puis `lecture_jo.py`.

## Pas encore lu

Le décret n° 68-168 (Rhône, cantons des communes venues de l'Ain et de
l'Isère) : pas de PDF. Le tableau du décret du 16 janvier 1985 (noms des
cantons de Rennes et d'Auch) : mis en page en tableau, illisible tel quel.

## Suite, 11 octobre 2026 — posé

`sql/110_pose_lecture_jo.sql` a posé ces lectures dans les trous le 11 octobre
(règle C ; 691 périodes avec les transferts des tables du JO, voir
`cantons/note_decrets.md` (partie « Les tables analytiques du JO »)). Toussus-le-Noble et Châteaufort, que la base gardait
à Bièvres jusqu'en 1976, sont corrigées par `sql/111_corrige_transferts.sql` :
Versailles-Sud dès le 29 novembre 1969.
