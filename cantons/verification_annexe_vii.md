# Vérification de l'annexe VII — résultat

`cantons/verif_annexe_vii.py` confronte, département par département, l'écart
cantonal 1940→1999 de la base à ce que l'annexe VII explique.

    cantons_1999 − cantons_1940  ==  créations − disparitions

## Le résultat

**56 départements sur 85 bouclent exactement.** La transcription des 39 pages
est donc juste sur les deux tiers du pays, contrôlée par un calcul indépendant.

Onze départements sont écartés d'emblée, le test ne pouvant s'y appliquer :

| département | pourquoi |
|---|---|
| 75 | Paris n'a pas de cantons dans la base, mais des arrondissements |
| 91, 92, 93, 94, 95 | créés en 1964 ; leurs cantons de 1940 sont ceux de la Seine ou de la Seine-et-Oise, comptés sous leur code moderne |
| 78 | héritier partiel de la Seine-et-Oise démembrée |
| 2A, 2B | Corse recodée 20 → 2A/2B en 1976 ; l'annexe classe tout sous 20 |
| 13, 69 | Marseille et Lyon repliées en pseudo-cantons par `25_pseudo_canton.sql` |

## Ce que les 29 désaccords restants disent

Ce ne sont pas des erreurs de lecture. **L'annexe VII s'arrête au découpage de
1986 ; la comparaison va jusqu'en 1999.** Les cantons créés dans cet intervalle
de treize ans lui échappent par construction.

La démonstration tient dans la coïncidence des deux mesures. Pour chaque
département, le nombre de cantons de 1999 dont le nom n'apparaît **nulle part**
dans l'annexe égale son résidu :

| dép. | résidu | cantons non cités |
|---|---|---|
| 81 | +3 | Albi-Est, Albi-Ouest, Castres-Ouest |
| 34 | +3 | Castelnau-le-Lez, Lattes, Pignan |
| 31 | +3 | Blagnac, Portet-sur-Garonne, Tournefeuille |
| 35 | +2 | Betton, Cesson-Sévigné |
| 54 | +2 | Malzéville, Seichamps |
| 59 | +3 | Douai-Nord-Est, Seclin-Nord |

Et leurs noms sont ceux qu'on attend : **des cantons périurbains portant des
noms de communes**, signature des créations de la fin des années 1980.

À l'inverse, cinq départements — Sarthe, Yonne, Vaucluse, Tarn-et-Garonne,
Indre-et-Loire — ont un résidu non nul mais **aucun canton non cité**. Leur
écart vient du comptage, pas d'une lacune : le texte de l'annexe y emploie des
formes que la convention « division / dédoublement » ne suffit pas à trancher.

### Un ordre de grandeur inédit

La somme des résidus positifs, minorée des négatifs, donne **une quarantaine de
cantons créés entre 1986 et 1999** en métropole. C'est un chiffre que ni
l'annexe ni le COG ne donnent — le COG ne commence qu'en 1999 — et il complète
la mesure du trou par son extrémité la plus récente.

## Le cas du Pas-de-Calais — clos

**Résidu +9**, le plus fort de tous, avec douze cantons non cités : Barlin,
Berck, Dainville, Divion, Douvrin, Montigny-en-Gohelle, Noyelles-sous-Lens,
Le Portel, Sains-en-Gohelle, Béthune-Est, plus deux appariements ratés
(Bruay-en-Artois renommé Bruay-la-Buissière en 1987, Boulogne-N.O.).

Neuf créations inexpliquées dans un seul département, quand aucun autre ne
dépasse trois : la transcription était suspecte. **Les pages 810 et 811 ont été
relues : elles sont complètes.** Le département s'arrête bien au décret du
24.12.1984, dernier point « Cr. Calais-S.E. ».

Le résidu est donc réel, et il rejoint l'explication générale : neuf cantons
créés dans le bassin minier et le Boulonnais **entre 1986 et 1999**, hors de
portée de l'annexe. Le seul cas qui pouvait encore la contredire la confirme.

Une correction de date au passage : `Cr. Noeux-les-Mines` est le dernier point
du décret du 16.8.1973, non du 29.9.1975 qui ne porte que des changements de
dénomination. Sans effet sur le décompte.

## Ce que le contrôle a produit au passage

Deux résultats que la vérification n'était pas censée donner.

**L'Oise a livré une information absente du texte.** Le livre écrit « Cr.
Compiègne-N. et Compiègne-S. » sans dire ce qu'il advient de l'ancien canton de
Compiègne. Le solde arithmétique impose qu'il disparaisse : sans cela l'Oise
compterait un canton de trop. Le contrôle ne s'est pas contenté de valider, il a
tranché une ambiguïté de la source.

**Et il a corrigé une erreur de transcription réelle** : la ligne du 13.7.1973
de l'Oise, à cheval sur la coupure des pages 809 et 810, avait été saisie deux
fois sous forme tronquée.

## Limites du contrôle

Il ne mesure que des **effectifs**. Un canton créé et un autre supprimé le même
jour se compensent et passent inaperçus. Il ne dit rien des transferts de
communes entre cantons, que l'annexe VII ne recense de toute façon jamais.

Et le parseur reste approximatif : le texte de l'annexe est en français libre,
et la convention « division / dédoublement » n'est pas toujours suivie — la
Sarthe crée six cantons du Mans « par division des 3 anciens », qui disparaissent
en réalité alors que la convention voudrait qu'ils subsistent.
