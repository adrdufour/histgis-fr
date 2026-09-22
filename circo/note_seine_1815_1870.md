# Note de lecture — la banlieue de la Seine, 1815-1870

Écrite le 6 septembre 2026 d'après les planches « SEINE » de l'atlas
Gaudillère, **jouée le soir même, puis reprise après relecture des planches** —
`sql/91_seine_1815_1870.sql` pose 9 unités neuves, 4 renommages d'unité, 4 de
version et **519 rattachements**. Avec `89`, `90` et les fichiers parisiens,
**la Seine est continue de 1815 à 2012**.

    ce que la carte rend      atomes   union km²   recouvrement
      1825-06-01                 126     475,83          0,000
      1855-06-01                 128     475,68          0,000
      1866-06-01                 150     479,64          0,000

**1866 rend la Seine entière au centième** — 479,64 pour une Seine officielle
de 479,9. Le déficit du bois de Boulogne y disparaît : à cette date Paris est
sur la trame des 80 quartiers, qui couvre le Paris de 1860 bois compris.

**1855 valait 455,25 avant la relecture, il vaut 475,68 après** : les onze
annexées sont désormais rattachées, et la date rejoint 1825 à 0,15 km² près.
Les 24,39 km² que coûtait le refus de lire une carte à la place d'un texte
n'étaient donc pas un prix à payer — c'était une question à poser. *Le prix
d'un refus se mesure, et parfois la bonne réponse est de ne plus refuser.*

**Un trou hérité, trouvé en lisant la recette 6** : de 1860 à 1863 un anneau
vide sépare Paris de la grande banlieue. Les onze annexées meurent en 1859
selon ANR, mais la division électorale parisienne de 1857-1863 porte sur les
48 quartiers de Vasserot et court jusqu'en 1863. La source date la division de
1857 et l'annexion de 1860, et les deux ne coïncident pas. Le combler
demanderait de faire basculer Paris sur la trame des 80 au 1er janvier 1860 —
un changement dans `55`, pas ici.

## Ce que les planches disent, division par division

L'atlas ne se contente pas de signaler que des circonscriptions débordent de
Paris — **il cartographie la banlieue**, commune par commune, et numérote ses
circonscriptions. La colonne `remarque` du tableur (`rattaché hors-paris`)
n'était que la trace textuelle d'une chose entièrement dessinée à côté.

| division | la banlieue | numérotation |
|---|---|---|
| **1815** | deux collèges d'arrondissement, **Saint-Denis** (nord) et **Sceaux** (sud) | non numérotés sur la planche |
| **1820-1831** | **une seule circonscription** pour tout | « la **8ᵉ** circonscription de la Seine » (texte de la planche) |
| **1831-1848** | même découpage qu'en 1815 | **13ᵉ = Sceaux, 14ᵉ = Saint-Denis** (texte de la planche) |
| **1852-1857** | deux circonscriptions propres, hors Paris | **8** au nord, **9** au sud |
| **1857-1863** | idem | **9** au nord, **10** au sud |
| **1863-1869** | rattachée à deux circonscriptions **parisiennes** | **8** (Paris est + banlieue nord), **9** (Paris sud-est + banlieue sud) |
| **1869-1870** | idem | **8** et **9** |

**La bascule de 1863 s'explique par l'annexion.** Avant 1860, la « petite
banlieue » — les onze communes que Paris absorbe — est rattachée aux
circonscriptions parisiennes limitrophes, et c'est cela que marque
`rattaché hors-paris` : circos 1 et 2 en 1852-1857, circos 1, 2 et 5 en
1857-1863. La « grande banlieue », elle, forme ses deux circonscriptions
propres. Après 1860 il n'y a plus de petite banlieue, et la grande est
rattachée aux circos 8 et 9 de Paris.

## La ligne nord/sud, et elle se vérifie

La planche de 1815 porte la seule définition écrite de la frontière :

> « les deux arrondissements de Sceaux et de Saint-Denis étaient séparés, sur
> le territoire actuel de Paris, par la Seine à l'Ouest et la rue de Lagny à
> l'Est. »

Cette frontière est celle des arrondissements du département, et **le jalon
cantonal de 1954 la porte encore**. La nomenclature de la page 758 donne
l'arrondissement de chaque canton — 13 à Saint-Denis, 9 à Sceaux — et une fois
déployée sur les communes :

    Saint-Denis   37 communes   174,22 km²   centroïde y = 6 868 114
    Sceaux        43 communes   199,99 km²   centroïde y = 6 855 237

Sceaux forme **un seul bloc connexe**. Saint-Denis en forme **deux**, et le
second est **Boulogne-Billancourt seule**, 6,16 km², coupée de son
arrondissement par Paris. Ce n'est pas un défaut : Boulogne est sur la rive
DROITE, dans la boucle, et la planche de 1815 dit que la séparation suit la
Seine à l'ouest. *Deux sources séparées de cent trente-neuf ans décrivent la
même ligne, et l'anomalie de l'une confirme la règle de l'autre.*

## La petite banlieue, et Boulogne

Les planches relues nomment les onze annexées, et elles nomment aussi une
douzième commune que rien n'annonçait. `circo/seine_annexees_circo.csv`,
24 lignes, **prime sur la règle nord/sud** — le texte l'emporte sur la
déduction, et quatre garde-fous le vérifient.

| | 1852-1857 | 1857-1863 |
|---|---|---|
| circo 1 de Paris | Passy, Auteuil, **Boulogne** | idem |
| circo 2 de Paris | La Chapelle, Batignolles-Monceau, Montmartre | idem |
| circo 5 de Paris | — | une partie de Belleville |
| banlieue nord | Charonne, La Villette, Belleville | Charonne, La Villette |
| banlieue sud | Bercy, Grenelle, Vaugirard | idem |

    1852-1857   75-01  3   75-02  3   nord 33   sud 41   = 80, partition
    1857-1863   75-01  3   75-02  3   nord 32   sud 41   = 79, Belleville coupée

**BOULOGNE-BILLANCOURT N'EST PAS UNE ANNEXÉE.** C'est une commune de la
banlieue actuelle, que la ligne nord/sud de 1954 place dans l'arrondissement de
Saint-Denis, donc dans la circonscription de banlieue nord. Les planches la
donnent à la 1re circonscription **parisienne**. Le premier jeu l'a rattachée
au mauvais endroit pendant onze ans.

*Et l'indice était dans la mesure du matin.* Boulogne était la seconde
composante connexe de l'arrondissement de Saint-Denis, seule, coupée du reste
par Paris. J'y ai vu une confirmation de la ligne et je me suis arrêté là. Une
commune que Paris sépare de son arrondissement est précisément celle que Paris
capte électoralement. **Une anomalie qui confirme une règle peut en annoncer
une autre, et on cesse de lire dès qu'elle donne raison.**

## Ce qui reste non posé

* **Belleville en 1857-1863**, et elle seule. L'atlas le déclare lui-même :
  > « la commune de Belleville était divisée : deux bureaux de vote (rue
  > H. Chevreau et rue du Combat, c'est-à-dire rue de Meaux actuelle) étaient
  > inclus dans la 5ᵉ circonscription, et le reste de la commune dans la 9ᵉ.
  > **Faute de précisions supplémentaires, la ligne de séparation cartographiée
  > ci-dessus est purement arbitraire.** »

  Belleville est donc **nommée et non attribuée**, comme les quartiers
  parisiens coupés par une rue dans `52` et `55` : son `unit_id` vaut
  `(coupee)` dans le CSV, et un garde-fou refuse qu'on la pose quand même.

* **Les onze annexées, en 1815-1820 et 1831-1848.** Mesuré sur l'export :
  Passy, Auteuil, Montmartre, Belleville, Vaugirard… ne sont dessinées ni à
  1817 ni à 1840. Elles portent le côté `annexee`, qui ne rejoint que la
  division dont le côté vaut `tout` — 1820-1831 — et les deux autres divisions
  partagent la banlieue entre Saint-Denis et Sceaux sans qu'aucun côté leur ait
  été donné. La note disait « leur côté doit venir d'ailleurs » ; il n'est
  jamais venu. *Une réserve écrite n'est pas une réserve levée.*

  Le comblement tient en onze lignes, et il demande une lecture des planches
  1815 et 1831-1848 : de quel côté de la limite tombe chacune ? La règle
  écrite — « la Seine à l'Ouest, la rue de Lagny à l'Est » — mettrait Grenelle
  et Vaugirard à Sceaux et les autres à Saint-Denis, **Bercy restant douteuse**
  puisqu'elle est rive droite mais au sud de la rue de Lagny. À ne pas trancher
  par déduction géographique.

* **L'anneau vide de 1860-1863.** Les annexées meurent en 1859 selon ANR — la
  recette 3 le montre, leurs rattachements s'arrêtent au 1er janvier 1859 et
  non à 1863 — mais la division parisienne de 1857-1863 porte sur les
  48 quartiers de Vasserot. À 1861 la carte rend 48 + 69, et l'anneau est là.
  Le combler demande de basculer Paris sur la trame des 80 au 1er janvier
  1860 : un changement dans `55`.

## La réserve qui porte tout

La répartition Saint-Denis / Sceaux est lue **à 1954** et projetée sur
1815-1870. Ce qui la soutient : la planche de 1815 nomme les deux mêmes
arrondissements, la ligne décrite (la Seine à l'ouest) explique l'anomalie de
Boulogne mesurée à 1954, et les arrondissements sont des cadres stables. Ce qui
ne la soutient pas : rien n'interdit qu'une commune ait changé
d'arrondissement entre 1815 et 1954 — **et Boulogne a montré que la ligne
administrative n'est pas la ligne électorale**, ce que seule la lecture des
planches pouvait dire.

C'est la même forme d'hypothèse que celle de `88`, et elle se déclare de la
même façon : `provisoire = true`, et la réserve écrite avant le code.
