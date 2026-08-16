# Datation des 64 cantons `post_1986` — état après dépouillement des JO

**57 datés · 7 faux positifs · 0 piste restante — CLOS le 15 août 2026.**

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

Sources : JO numérisés de `sources/modif_canton/` ; Légifrance, fonds JORF ;
nomenclatures cantonales 1872 et 1932 de `sources/trfgis/`. Licence etalab-2.0.


---

## Les deux dernières pistes, closes le 15 août 2026

Les deux PDF ont été déposés et dépouillés. **Tous deux portent une couche
texte native** : aucun OCR n'a été nécessaire, contrairement au volume de 1954.

### Châtenois-les-Forges (90) — création confirmée

**Décret n° 67-672 du 9 août 1967**, JO du 10 août, page 8012. Le texte est sur
deux colonnes ; `pdftotext -layout` les entrelace et rend l'article illisible.
Il faut découper par colonne : `pdftotext -f 4 -l 4 -x 320 -W 320`.

> « Art. 1er. — En remplacement du canton de Belfort (territoire de Belfort),
> sont créés les sept cantons dénommés et composés comme suit : […]
> **5. Canton de Châtenois-les-Forges** comprenant les communes de
> Châtenois-les-Forges, Argiésans, Banvillars, Bavilliers, Bermont, Botans,
> Buc, Dorans, Trétudans, Urcerey et Vourvenans. »

Le décret crée sept cantons d'un coup : Belfort-Centre, -Est, -Ouest et -Nord
(quatre fractions de la ville), plus Châtenois-les-Forges, Danjoutin et Valdoie.

**Onze communes, onze appariements**, et deux d'entre eux méritent d'être
notés : **Trétudans (90097) et Vourvenans (90106) ne sont pas des fautes
d'OCR.** Ce sont deux communes réelles, fusionnées dans **Trévenans le
1ᵉʳ juillet 1972** — cinq ans après la création du canton. Le premier réflexe
avait été de « corriger » Vourvenans en Trévenans par ressemblance : c'eût été
remplacer le fait par le successeur du fait. `insee_mvt.libelle_av` tranche en
une requête.

Seul « Bue » est une vraie erreur de lecture, pour **Buc** (90020) — un `c` lu
`e`, une seule lettre.

### Pau-Sud (64) — ce n'est PAS le 75-872

Le décret n° 75-872 du 3 septembre 1975 ne crée rien. Son article 1er dit :

> « Les quatrième et huitième alinéas de l'article 1er du **décret susvisé**
> sont remplacés par les dispositions suivantes : "Canton de Pau-IV-Ouest
> comprenant les communes de Narcastet, Rontignon, Uzos, Mazères-Lezons et
> Gelos ainsi que la portion du territoire de la ville de Pau…" »

Le décret visé est le **n° 73-669 du 13 juillet 1973**. C'est lui le texte
créateur ; le 75-872 se borne à redéfinir deux de ses alinéas.

**Trois enseignements, dont un désagréable.**

1. Le canton s'appelle **Pau-III-Sud** en 1975 et **Pau-Sud** au COG de 1999.
   La numérotation romaine a sauté entre les deux. C'est le cinquième
   déguisement du même phénomène, après le changement de département, le
   silence de la source, le renommage et la renumérotation du Havre.

2. **Le décret créateur était déjà dans nos fichiers.** `73-669` figure dans
   `communes_coupees_1973_1984.csv` — mais avec ses seules lignes **Bayonne et
   Biarritz**, qui relèvent de son article 2. **L'article 1er, celui de Pau,
   manque à la transcription.** Nous avons donc cherché pendant des semaines un
   décret que nous possédions, dont une moitié n'avait pas été relevée.

3. Conséquence à porter au dossier de l'exhaustivité :
   `communes_coupees_1973_1984.csv` **n'est pas complet décret par décret**. Un
   décret présent dans le fichier ne garantit pas que tous ses articles y
   soient. Toute mesure de couverture fondée sur le nombre de décrets présents
   surestime donc la couverture réelle.
