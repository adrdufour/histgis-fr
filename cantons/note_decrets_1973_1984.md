# Décrets cantonaux 1973 / 1982 / 1984 — index et accès aux délimitations

Fichier produit : `cantons/decrets_1973_1984.csv` (136 décrets, 8 dates).

## 1. Ce qui est acquis

136 décrets identifiés sur Légifrance, un par département (sauf 82-82, « divers
départements »). Colonnes : date de signature, date de publication au JO, numéro
de décret, code et nom du département à l'époque, objet, cantons cités dans le
titre (1982 seulement), identifiant et URL Légifrance, identifiant du JO numérisé.

| Date de signature | Décrets | Plage de numéros | JO de publication |
|---|---|---|---|
| 1973-07-13 | 28 | 73-651 → 73-678 | 17 juillet 1973, n° 164 |
| 1973-07-23 | 18 | 73-712 → 73-729 | 25 juillet 1973, n° 171 |
| 1973-08-02 | 14 | 73-761 → 73-774 | 4 août 1973, n° 180 |
| 1973-08-16 | 12 | 73-810 → 73-821 | 17 août 1973, n° 190 |
| 1982-01-15 | 17 | 82-22 → 82-38 | 16 janvier 1982, n° 13 (NC) |
| 1982-01-20 | 16 | 82-51 → 82-66 | 22 janvier 1982, n° 18 |
| 1982-01-25 | 10 | 82-77 → 82-86 | 26 janvier 1982, n° 21 |
| 1984-12-24 | 21 | 84-1222 → 84-1242 | 30 décembre 1984, n° 305 (NA) |

**Contrôle de complétude** : sur chacune des 8 dates la numérotation est
strictement contiguë, sans trou. L'énumération est donc exhaustive : aucun
décret de la série n'a été manqué.

## 2. Ce qui bloque pour les délimitations

Pour les textes antérieurs à 1990, **Légifrance ne conserve que le titre**. La
page d'un décret de 1973 ne contient aucun article : le corps du texte
(« Art. 1er — Le canton de X est composé des communes de… ») n'existe que dans
le **JO papier numérisé**.

Ces PDF (≈ 28 Mo par numéro) sont derrière un **CAPTCHA de téléchargement**
(`download-link-secure` → `captchaLink` dans `legifrance.js`). Je ne peux pas le
franchir. Le téléchargement manuel se fait depuis la page du décret, bouton
« Télécharger le Journal officiel… (version papier numérisée) ». Il n'y a que
**8 PDF à récupérer** — un par date, pas un par décret : tous les décrets d'une
même date sont dans le même numéro du JO.

Une fois les 8 PDF dans `modif_canton/`, l'OCR et le découpage par décret sont
automatisables.

## 3. Sources de repli pour les délimitations

- **Titres de 1982** : les décrets de janvier 1982 nomment les cantons créés
  dans leur intitulé — repris dans la colonne `cantons_cites_dans_le_titre`.
  Ceux de 1973 et 1984 ne le font pas.
- **COG INSEE** : le diff commune → canton entre COG 1972/1975 et COG 1982/1985
  reconstitue la composition exacte des cantons créés. Machine-lisible et
  exhaustif, mais ce n'est pas la source juridique — à traiter comme un contrôle,
  pas comme un acte (cf. `METHODE.md`, cohérence ≠ exactitude).

## 4. Écarts relevés avec `mouvements_cantonaux.csv`

Tous les départements présents dans le registre à ces dates ont bien un décret
correspondant. **L'inverse n'est pas vrai** : 15 décrets visent des départements
pour lesquels le registre n'enregistre aucune décision à cette date.

| Date | Départements à décret sans décision au registre |
|---|---|
| 1973-07-23 | 03 Allier, 35 Ille-et-Vilaine |
| 1973-08-02 | 38 Isère, 43 Haute-Loire, 84 Vaucluse, 85 Vendée |
| 1973-08-16 | 01 Ain |
| 1982-01-15 | 17 Charente-Maritime, 78 Yvelines |
| 1982-01-20 | 2B Haute-Corse, 49 Maine-et-Loire |
| 1982-01-25 | 35 Ille-et-Vilaine |
| 1984-12-24 | 09 Ariège, 28 Eure-et-Loir, 32 Gers |

À vérifier : soit ces mouvements sont datés autrement dans le registre, soit ce
sont des lacunes de l'annexe VII. Dans les deux cas c'est notable.

---

Source : Légifrance, fonds JORF, recherche par date de signature.
Licence etalab-2.0.
