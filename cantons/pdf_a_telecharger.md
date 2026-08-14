# Datation des 64 cantons `post_1986` — état après dépouillement des JO

**55 datés · 7 faux positifs · 2 pistes restantes.**

Détail canton par canton dans `cantons_post1986_datation.csv`.

## Ce que les quatre PDF ont donné

| PDF | Décret | Résultat |
|---|---|---|
| `JORF_19880422_95` | 88-398 (Isère) | ✅ **Saint-Ismier confirmé** — « Il est créé un canton de Saint-Ismier », détaché de Meylan, effet au 1er septembre 1988 |
| `JORF_19820128_23` | 82-95 (Pyrénées-Atlantiques) | ❌ crée Pau-Centre, Pau-Est, Pau-Nord, Lescar, Billère, Anglet-Nord — **pas Pau-Sud** |
| `JORF_19820128_23` | 82-97 (Seine-Maritime) | ❌ crée Sotteville-lès-Rouen-Est et Ouest, Saint-Étienne-du-Rouvray — **pas Le Havre** |
| `JORF_19700121_17` | décret du 19 janvier 1970 | ❌ crée Delle, Beaucourt, Grandvillars — **pas Châtenois-les-Forges** |

Un sur quatre. Les corps de 82-95 et 82-97 se trouvaient dans le JO **ordinaire**
du 28 janvier, pas dans le numéro complémentaire.

## Le Havre : ni création ni faux positif ordinaire, une renumérotation

Le décret **n° 91-218 du 27 février 1991** (texte intégral sur Légifrance, aucun
PDF nécessaire) :

> « Art. 1er. — Les cantons du Havre-I et du Havre-II sont réunis en un seul
> canton qui prend la dénomination du Havre-I.
> Art. 2. — Les cantons du Havre-III, IV, V, VI, VII, VIII, IX et X prennent
> respectivement les dénominations du Havre-II, III, IV, V, VI, VII, VIII et IX. »

Le « Havre 6e canton » de 1999 est donc **l'ancien Havre-VII**, décalé d'un rang.
Aucun canton n'a été créé.

**Conséquence au-delà du Havre** : toute la série havraise est décalée après
1991. Un appariement par nom entre un état antérieur et le COG 1999 associera
systématiquement le mauvais canton — et sans lever d'alerte, puisque les deux
noms existent de part et d'autre. À vérifier partout où un chef-lieu porte des
cantons numérotés (Le Havre, Rouen, Nice, Marseille…).

C'est le quatrième déguisement du même phénomène, après le changement de
département, le silence de la source et le renommage.

## Les 7 faux positifs

| Canton | Raison |
|---|---|
| 50 Ducey (5013), La Haye-du-Puits (5016), Sartilly (5042) | présents en 1872 et 1932 sous le même code |
| 43 Saugues (4325) | idem |
| 38 Vizille (3844) | idem |
| 64 Arthez-de-Béarn (6403) | « ARTHEZ » en 1872 — renommage |
| 76 Le Havre 6e (7656) | renumérotation par le décret 91-218 |

## Les 2 pistes restantes

Codes 6447 et 9010 : **absents des nomenclatures de 1872 et de 1932**, ce sont
donc de vraies créations. Les décrets restants pour ces départements :

| PDF | JO | Décret | Pour |
|---|---|---|---|
| `JORF_19750926_224` | 26 septembre 1975 | **75-872**, Pyrénées-Atlantiques | Pau-Sud |
| `JORF_19670810_185` | 10 août 1967 | **67-672**, Territoire de Belfort | Châtenois-les-Forges |

- 75-872 → https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000000307309
- 67-672 → https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000000702076

Ce sont les **derniers** décrets cantonaux que Légifrance recense pour ces deux
départements entre 1943 et 1999. S'ils ne contiennent pas ces cantons, la
création vient d'un décret dont le titre ne nomme pas le département (formule
« dans divers départements ») et il faudra changer de méthode de recherche.

## Rappel de méthode

Sur les 12 pistes fondées sur le seul titre du décret, **9 étaient fausses**
(73-664, 73-669, 84-1230, 84-1240, 82-95, 82-97, décret de 1970, et les deux
replis implicites). Une seule s'est vérifiée du premier coup : 88-398.

Le titre d'un décret donne un département et une date. Il ne dit jamais quels
cantons sont créés, et le taux d'erreur observé ici — 9 sur 12 — interdit de
l'utiliser autrement que comme piste à vérifier.

---

Sources : JO numérisés de `modif_canton/` ; Légifrance, fonds JORF ;
nomenclatures cantonales 1872 et 1932 de `trfgis/`. Licence etalab-2.0.
