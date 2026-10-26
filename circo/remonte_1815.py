#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
remonte_1815.py — reconstruire les découpages de 1815 à 1870 depuis Gaudillère

    python3 circo/remonte_1815.py                 # contrôle seul
    python3 circo/remonte_1815.py --dep 89        # un département
    python3 circo/remonte_1815.py --sql           # écrit le SQL de chargement

Le principe
-----------
L'atlas décrit chaque découpage **par différence** avec un autre : 1852 par
rapport à 1876, 1820 par rapport à 1852, 1831 par rapport à 1815, 1815 par
rapport à 1876. C'est une chaîne, et elle se résout en partant de la seule
composition que nous ayons — celle de 1876, déjà en base.

Toutes les tournures de l'atlas se ramènent à DEUX opérations :

    reprend   une circonscription est l'union de circonscriptions de référence,
              éventuellement augmentée de cantons nommés
    deplacer  des cantons changent de circonscription

« La 3e perd les cantons A, B au profit de la 2e » et « la 1re gagne les
cantons C, D » sont la MÊME opération : des cantons vont vers une
circonscription. Leur origine n'a pas à être écrite, elle se calcule dans le
découpage de référence. C'est ce qui rend la saisie sûre : rien à déduire à la
main, donc rien à se tromper.

LA RECETTE, ET POURQUOI ELLE EST FORTE
--------------------------------------
À chaque période, les cantons attribués doivent former une **partition** des
cantons du département : chacun dans une circonscription et une seule, aucun
oublié. Deux fautes de saisie sur trois la brisent — un canton nommé deux fois,
un canton oublié, un nom mal orthographié.

Ce n'est pas une preuve d'exactitude : une permutation de deux circonscriptions
passerait au travers. Mais c'est un filet serré, et il ne coûte rien.

CE QUE CE FICHIER NE DÉCIDE PAS
-------------------------------
Les périodes sans découpage — « pas de découpage, collège de département » pour
les Vosges en 1820-1831 et 1828-1831, et l'intervalle 1848-1852 partout (la
Deuxième République vote au scrutin de liste départemental) — ne reçoivent
RIEN. Comme pour 1941-1945 et le trou cantonal : `snapshot` ne renverra pas un
découpage faux, il n'en renverra aucun.
"""

import argparse
import collections
import csv
import re
import sys
import unicodedata
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
B = RACINE / "build"

# La date à laquelle on lit la composition de référence. Le segment 1876 court
# jusqu'en 1881 ; on échantillonne à l'intérieur, pas sur sa borne.
REF_DATE = "1878-12-01"


def cle(s):
    s = unicodedata.normalize("NFD", (s or "").lower())
    return "".join(c for c in s if c.isalnum())


# ---------------------------------------------------------------------------
# LES RÈGLES, transcrites de Gaudillère
#
# `base` : le découpage de référence, déjà calculé ou lu en base.
# `circos` : {numéro: {reprend: [...], plus: [...], reste: bool}}
# `deplacer` : [([cantons], vers)]
# `renommer` : {ancien: nouveau} — pour les découpages qui numérotent
#              simplement les circonscriptions existantes.
#
# Les noms de cantons sont ceux de la NOMENCLATURE, pas ceux de l'atlas :
# « Brienon » y est Brienon-sur-Armançon, « Saulxures » Saulxures-sur-Moselotte,
# « Saint-Sulpice » Saint-Sulpice-les-Feuilles.
#
# UNE AMBIGUÏTÉ NON LEVÉE : le « canton de Bains » des Vosges. La nomenclature
# porte Bains-les-Bains ET Plombières-les-Bains. On retient Bains-les-Bains, et
# on le signale — la recette ne peut pas trancher, les deux donnant une
# partition valide.
# ---------------------------------------------------------------------------
REGLES = {
"89": {
  "nom": "Yonne",
  "cantons_stables": "1815-1870 : aucune modification cantonale (Gaudillère)",
  "periodes": [
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Tonnerre", "Avallon"],
              "plus": ["Vermenton", "Coulanges-sur-Yonne", "Chablis"]},
        "2": {"reprend": ["Sens"],
              "plus": ["Villeneuve-sur-Yonne", "Cerisiers", "Brienon-sur-Armançon",
                       "Joigny", "Saint-Julien-du-Sault"]},
        "1": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1852", "deplacer": [
        (["Vermenton", "Coulanges-sur-Yonne", "Chablis"], "2"),
        (["Charny", "Aillant", "Bléneau", "Saint-Fargeau"], "1")]},
    # « 1831-1848 : même découpage qu'en 1815 » — et 1815 est décrit par
    # rapport à 1876. La période 1831 hérite donc de 1815, calculé plus bas.
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "copie": True},
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Auxerre-1", "Auxerre-2"], "Auxerre")]},
  ]},

"88": {
  "nom": "Vosges",
  "cantons_stables": "1815-1870 : aucune modification cantonale (Gaudillère)",
  "periodes": [
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Saint-Dié"], "plus": ["Saales", "Schirmeck",
                                                  "Saulxures-sur-Moselotte"]},
        "1": {"reprend": ["Épinal", "Remiremont"],
              "moins": ["Saulxures-sur-Moselotte"]},
        "2": {"reprend": ["Neufchâteau", "Mirecourt"]}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876",
     "renommer": {"Épinal": "1", "Mirecourt": "2", "Neufchâteau": "3",
                  "Remiremont": "4", "Saint-Dié": "5"},
     "deplacer": [(["Saales", "Schirmeck"], "5")]},
    # 1828-1831 et 1820-1831 : « pas de découpage, collège de département ».
    # Rien n'est posé — voir l'en-tête.
    {"depuis": 1824, "jusqu": 1828, "base": "1831", "circos": {
        "2": {"reprend": ["2", "4"], "plus": ["Bains-les-Bains"]},
        "1": {"reprend": ["5", "1"], "moins": ["Bains-les-Bains"]}}},
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "deplacer": [
        (["Saales", "Schirmeck"], "Saint-Dié"),
        (["Bains-les-Bains"], "Mirecourt")]},
  ]},

"87": {
  "nom": "Haute-Vienne",
  "cantons_stables": "1815-1870 : aucune modification cantonale (Gaudillère)",
  "periodes": [
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Limoges-1", "Limoges-2"],
              "plus": ["Saint-Germain-les-Belles", "Bessines-sur-Gartempe",
                       "Châteauponsac", "Saint-Sulpice-les-Feuilles"]},
        "2": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1869, "base": "1869", "deplacer": [
        (["Nieul", "Aixe-sur-Vienne"], "2")]},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Limoges-Nord", "Limoges-Sud"]},
        "2": {"reprend": ["Limoges-2"], "plus": ["Ambazac"]},
        "3": {"reprend": ["Bellac"]},
        "4": {"reprend": ["Saint-Yrieix"]},
        "5": {"reprend": ["Rochechouart"]}}},
    {"depuis": 1821, "jusqu": 1831, "base": "1831", "circos": {
        "2": {"reprend": ["1", "2", "4"], "moins": ["Châlus"]},
        "1": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1821, "base": "1831", "circos": {
        "2": {"reprend": ["1", "2"], "moins": ["Laurière"]},
        "1": {"reste": True}}},
    {"depuis": 1815, "jusqu": 1820, "base": "1876",
     "fusionner": [(["Limoges-1", "Limoges-2"], "Limoges")],
     "deplacer": [(["Laurière"], "Bellac")]},
  ]},
"74": {
  "nom": "Haute-Savoie",
  "cantons_stables": "département français depuis 1860 seulement — rien avant",
  "periodes": [
    {"depuis": 1860, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Annecy", "Saint-Julien"]},
        "2": {"reprend": ["Thonon", "Bonneville"]}}},
  ]},

"77": {
  "nom": "Seine-et-Marne",
  "periodes": [
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Meaux"], "plus": ["Tournan-en-Brie", "Brie-Comte-Robert"]},
        "3": {"reprend": ["Provins", "Coulommiers"]},
        "1": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1863", "deplacer": [
        (["Brie-Comte-Robert", "Tournan-en-Brie"], "3")]},
    {"depuis": 1852, "jusqu": 1863, "base": "1820", "copie": True},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "copie": True},
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
  ]},

"79": {
  "nom": "Deux-Sèvres",
  "periodes": [
    {"depuis": 1857, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Melle", "Niort-2"], "plus": ["Niort-1"],
              "moins": ["La Mothe-Saint-Héray"]},
        "3": {"reprend": ["Bressuire"],
              "plus": ["Moncoutant", "Airvault", "Saint-Loup-sur-Thouet",
                       "Thénezay"]},
        "2": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "1": {"reprend": ["Melle", "Niort-1", "Niort-2"]},
        "2": {"reprend": ["Parthenay", "Bressuire"]}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1852", "circos": {
        "1": {"reprend": ["2"], "plus": ["Champdeniers",
              "Saint-Maixent-l'École-1", "Saint-Maixent-l'École-2"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "copie": True},
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Niort-1", "Niort-2"], "Niort")]},
  ]},

"81": {
  "nom": "Tarn",
  "periodes": [
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Albi"], "plus": ["Cordes", "Cadalen", "Lautrec",
                                             "Montredon-Labessonnié"]},
        "2": {"reprend": ["Castres-1", "Castres-2"],
              "moins": ["Lautrec", "Montredon-Labessonnié"]},
        "3": {"reste": True}}},
    {"depuis": 1857, "jusqu": 1863, "base": "1863", "deplacer": [
        (["Puylaurens"], "2")]},
    {"depuis": 1852, "jusqu": 1857, "base": "1857", "deplacer": [
        (["Cadalen"], "3"), (["Puylaurens"], "3")]},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"reprend": ["Albi"]},
        "3": {"reprend": ["Castres-1", "Castres-2"],
              "plus": ["Montredon-Labessonnié", "Roquecourbe", "Labruguière",
                       "Dourgne"]},
        "2": {"cantons": ["Mazamet", "Castres", "Vielmur-sur-Agout", "Lautrec"]},
        "4": {"reprend": ["Gaillac"]},
        "5": {"reprend": ["Lavaur"]}}},
    # L'atlas écrit « par rapport à 1852 » mais cite les 2e, 3e et 5e
    # circonscriptions : 1852 n'en a que trois. La base ne peut être que 1831,
    # qui en a cinq. INTERPRÉTATION signalée.
    {"depuis": 1820, "jusqu": 1831, "base": "1831", "circos": {
        "2": {"reprend": ["2", "3", "5"],
              "moins": ["Graulhet", "Montredon-Labessonnié"]},
        "1": {"reste": True}}},
    {"depuis": 1815, "jusqu": 1820, "base": "1831", "circos": {
        "Castres": {"reprend": ["2", "3"]},
        "Lavaur": {"reprend": ["5"]},
        "Albi": {"reprend": ["1"]},
        "Gaillac": {"reprend": ["4"]}}},
  ]},

"82": {
  "nom": "Tarn-et-Garonne",
  "periodes": [
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Montauban-1", "Montauban-2"],
              "plus": ["Lauzerte", "Montaigu-de-Quercy"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Montauban-Est", "Montauban-Ouest"]},
        "2": {"cantons": ["Caylus", "Saint-Antonin", "Caussade",
                          "Montpezat-de-Quercy", "Nègrepelisse",
                          "Monclar-de-Quercy", "Molières", "Lafrançaise",
                          "Villebrumier"]},
        "3": {"cantons": ["Lavit", "Saint-Nicolas-de-la-Grave",
                          "Castelsarrasin", "Montech", "Beaumont-de-Lomagne",
                          "Verdun-sur-Garonne", "Grisolles"]},
        "4": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1831", "circos": {
        "1": {"reprend": ["1", "2"], "plus": ["Montech", "Grisolles"]},
        "2": {"reste": True}}},
    {"depuis": 1815, "jusqu": 1820, "base": "1831", "circos": {
        "Moissac": {"reprend": ["4"]},
        "Montauban": {"reprend": ["1", "2"]},
        "Castelsarrasin": {"reprend": ["3"]}}},
  ]},

"84": {
  "nom": "Vaucluse",
  "periodes": [
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"cantons": ["Valréas", "Bollène", "Orange-Ouest", "Orange-Est",
                          "Vaison-la-Romaine", "Beaumes", "Malaucène",
                          "Carpentras-Nord", "Carpentras-Sud", "Bédarrides",
                          "Avignon-Nord"]},
        "2": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1869, "base": "1876", "circos": {
        "2": {"cantons": ["Apt", "Gordes", "Bonnieux", "Cadenet", "Pertuis",
                          "Malaucène", "Beaumes", "Vaison-la-Romaine",
                          "Orange-Est", "Orange-Ouest", "Bollène", "Valréas"]},
        "1": {"reste": True}}},
    # Avignon-Sud n'a en 1876 qu'un atome-fraction, sans circonscription : la
    # « copie » de 1876 le laissait orphelin (partition rompue). Il suit
    # Avignon-Nord, comme ailleurs les cantons d'une même ville (4 oct. 2026).
    {"depuis": 1831, "jusqu": 1848, "base": "1876",
     "deplacer": [(["Avignon-Sud"], "Avignon")]},
    # Telle qu'écrite, cette règle ne change RIEN : Avignon-Nord et Bédarrides
    # sont déjà dans la 1re en 1869, et Pernes, Mormoiron et Sault n'y sont pas.
    # Transcrite littéralement et SIGNALÉE — la base visée est peut-être 1852.
    {"depuis": 1820, "jusqu": 1831, "base": "1869", "circos": {
        "1": {"reprend": ["1"], "plus": ["Avignon-Nord", "Bédarrides"],
              "moins": ["Pernes-les-Fontaines", "Mormoiron", "Sault"]},
        "2": {"reste": True}}},
    {"depuis": 1815, "jusqu": 1820, "base": "1876",
     "deplacer": [(["Avignon-Sud"], "Avignon")]},
  ]},

"86": {
  "nom": "Vienne",
  "periodes": [
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Montmorillon", "Châtellerault"],
              "moins": ["Lencloître"]},
        "2": {"reprend": ["Loudun"],
              "plus": ["Lencloître", "Mirebeau", "Neuville", "Vouillé",
                       "Saint-Georges", "Saint-Julien-l'Ars", "Poitiers-Nord"]},
        "3": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"reprend": ["Poitiers-1", "Poitiers-2", "Civray"]},
        "2": {"reste": True}}},
    {"depuis": 1821, "jusqu": 1831, "base": "1852", "deplacer": [
        (["Saint-Georges"], "2")]},
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "1": {"reprend": ["Loudun", "Poitiers-1", "Poitiers-2"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "copie": True},
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Poitiers-1", "Poitiers-2"], "Poitiers")]},
  ]},

"80": {
  "nom": "Somme",
  # « Canton de Sains » : la nomenclature 1870-2012 n'en a aucun. Le
  # *Dictionnaire historique et archéologique de la Picardie* (1909) range
  # Sains-en-Amiénois dans le **canton de Boves** : le chef-lieu a été
  # transféré entre 1869 et 1870, et TRF-GIS ne connaît que le nom d'après.
  # INTERPRÉTATION — c'est le seul canton de l'arrondissement d'Amiens que la
  # partition laisse alors sans emploi, ce qui la confirme sans la prouver.
  "periodes": [
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Péronne-1", "Péronne-2"]},
        "4": {"reprend": ["Montdidier"], "plus": ["Boves", "Conty"]},
        "2": {"reprend": ["Abbeville-1", "Abbeville-2"],
              "plus": ["Saint-Valery-sur-Somme", "Ault"]},
        "5": {"reprend": ["Doullens"],
              "plus": ["Picquigny", "Villers-Bocage", "Corbie"]},
        "1": {"reste": True}}},
    {"depuis": 1863, "jusqu": 1869, "base": "1869", "circos": {
        "3": {"reprend": ["3"], "plus": ["Rosières-en-Santerre"],
              "moins": ["Albert"]},
        "2": {"reprend": ["2"]},
        "5": {"reprend": ["5"], "moins": ["Villers-Bocage"]},
        "1": {"reprend": ["1"], "plus": ["Conty"]},
        "4": {"reste": True}}},
    {"depuis": 1857, "jusqu": 1863, "base": "1863", "deplacer": [
        (["Corbie"], "4")]},
    {"depuis": 1852, "jusqu": 1857, "base": "1857", "deplacer": [
        (["Roye"], "3"),
        (["Conty"], "4"),
        (["Moyenneville", "Gamaches", "Hallencourt"], "2"),
        (["Ailly-le-Haut-Clocher", "Villers-Bocage"], "5")]},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Amiens-1", "Amiens-2", "Amiens-3", "Amiens-4"]},
        "3": {"cantons": ["Abbeville-Nord", "Abbeville-Sud"]},
        "6": {"cantons": ["Montdidier", "Roye", "Rosières-en-Santerre",
                          "Moreuil", "Ailly-sur-Noye"]},
        "5": {"cantons": ["Acheux-en-Amiénois", "Doullens", "Bernaville",
                          "Domart"]},
        "7": {"cantons": ["Albert", "Bray", "Chaulnes", "Combles", "Péronne",
                          "Roisel", "Nesle", "Ham"]},
        "4": {"cantons": ["Rue", "Crécy-en-Ponthieu", "Nouvion",
                          "Ailly-le-Haut-Clocher", "Saint-Valery-sur-Somme",
                          "Ault", "Moyenneville", "Hallencourt", "Gamaches"]},
        "2": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1831", "circos": {
        "1": {"reprend": ["3", "4"], "plus": ["Bernaville", "Domart"]},
        "2": {"reprend": ["1"]},
        "3": {"reprend": ["2"], "plus": ["Albert", "Bray",
                                          "Acheux-en-Amiénois", "Doullens"]},
        "4": {"reste": True}}},
    {"depuis": 1815, "jusqu": 1820, "base": "1831", "circos": {
        "Abbeville": {"reprend": ["3", "4"]},
        "Doullens": {"reprend": ["5"]},
        "Amiens": {"reprend": ["1", "2"]},
        "Montdidier": {"reprend": ["6"]},
        "Péronne": {"reprend": ["7"]}}},
  ]},

"76": {
  "nom": "Seine-Maritime",
  "periodes": [
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"cantons": ["Rouen-1", "Rouen-2", "Rouen-3", "Rouen-4",
                          "Rouen-5", "Rouen-6", "Darnétal", "Boos"]},
        "2": {"cantons": ["Elbeuf", "Grand-Couronne", "Duclair", "Maromme",
                          "Pavilly", "Caudebec-en-Caux"]},
        "3": {"reprend": ["Neufchâtel"], "plus": ["Eu", "Clères", "Buchy"]},
        "4": {"reprend": ["Dieppe-2"], "plus": ["Dieppe", "Envermeu",
                                                 "Yerville", "Fontaine-le-Dun"]},
        "6": {"reprend": ["Le Havre-1", "Le Havre-2"],
              "plus": ["Goderville", "Saint-Romain-de-Colbosc",
                       "Le Havre-Sud"]},
        "5": {"reste": True}}},
    # Les six cantons de Rouen se répartissent deux par deux entre les trois
    # premières circonscriptions (Gaudillère, précisé le 28 août 2026). La 4e
    # reprend les CIRCONSCRIPTIONS Rouen-2 et Rouen-3 de 1876, dont les cantons
    # urbains lui sont ensuite repris — d'où l'ordre de déclaration.
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "4": {"reprend": ["Rouen-2", "Rouen-3"]},
        "1": {"cantons": ["Rouen-1", "Rouen-2"]},
        "2": {"cantons": ["Rouen-3", "Rouen-4"]},
        "3": {"cantons": ["Rouen-5", "Rouen-6"]},
        # `Le Havre-Sud` n'a qu'un atome, la fraction cantonale `16833#7628`
        # de la ville du Havre, et la couche circo de 1876 ne la rattache à
        # rien. Il est ajouté ici sur la foi de la BASE, non de l'atlas : ses
        # deux cantons frères, Le Havre-Nord et Le Havre-Est, sont dans la
        # circonscription Le Havre-1. Même défaut qu'Avignon-Sud.
        "5": {"reprend": ["Le Havre-1"], "plus": ["Montivilliers",
                                                   "Le Havre-Sud"]},
        "6": {"cantons": ["Criquetot-l'Esneval", "Fécamp", "Goderville",
                          "Saint-Romain-de-Colbosc", "Bolbec", "Lillebonne"]},
        "9": {"reprend": ["Neufchâtel"]},
        "8": {"cantons": ["Eu", "Tôtes", "Bellencombre",
                          "Longueville-sur-Scie", "Bacqueville-en-Caux"]},
        "7": {"cantons": ["Dieppe", "Offranville", "Envermeu"]},
        "11": {"cantons": ["Fontaine-le-Dun", "Saint-Valery-en-Caux",
                           "Cany-Barville", "Ourville-en-Caux", "Valmont"]},
        "10": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1831", "circos": {
        "1": {"reprend": ["1", "2", "3"]},
        "2": {"reprend": ["4"]},
        "3": {"reprend": ["5", "6"]},
        "4": {"reprend": ["10", "11"]},
        "5": {"reprend": ["8", "7"]},
        "6": {"reprend": ["9"]}}},
    {"depuis": 1815, "jusqu": 1820, "base": "1820", "circos": {
        "Neufchâtel": {"reprend": ["6"]},
        "Dieppe": {"reprend": ["5"]},
        "Rouen": {"reprend": ["1", "2"]},
        "Yvetot": {"reprend": ["4"]},
        "Le Havre": {"reprend": ["3"]}}},
  ]},

"78": {
  "nom": "Seine-et-Oise",
  "periodes": [
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Corbeil", "Étampes"],
              "plus": ["Dourdan-Nord", "Dourdan-Sud"]},
        "4": {"reprend": ["Mantes"], "plus": ["Meulan", "Montfort-l'Amaury",
                                               "Limours", "Rambouillet"]},
        "3": {"reprend": ["Pontoise-1", "Pontoise-2"], "plus": ["Poissy"]},
        "1": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1869, "base": "1869", "deplacer": [
        (["Meulan"], "3")]},
    # « par rapport à 1876 » (précisé le 28 août 2026). La 2e reprend la
    # circonscription Versailles-1, qui contient les trois cantons de
    # Versailles ; la 1re les lui reprend, d'où l'ordre.
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "2": {"reprend": ["Versailles-1"], "plus": ["Sèvres", "Palaiseau"]},
        "1": {"cantons": ["Versailles-Nord", "Versailles-Ouest",
                          "Versailles-Sud"]},
        "3": {"reprend": ["Corbeil"]},
        "4": {"reprend": ["Étampes"]},
        "5": {"reprend": ["Mantes"]},
        "6": {"reprend": ["Rambouillet"]},
        "7": {"reprend": ["Pontoise-1", "Pontoise-2"]}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1831", "circos": {
        "1": {"reprend": ["7"]},
        "2": {"reprend": ["3", "4"]},
        "3": {"reprend": ["5", "6"]},
        "4": {"reprend": ["1", "2"]}}},
    {"depuis": 1815, "jusqu": 1820, "base": "1831", "circos": {
        "Rambouillet": {"reprend": ["6"]},
        "Mantes": {"reprend": ["5"]},
        "Pontoise": {"reprend": ["7"]},
        "Versailles": {"reprend": ["1", "2"]},
        "Corbeil": {"reprend": ["3"]},
        "Étampes": {"reprend": ["4"]}}},
  ]},

"85": {
  "nom": "Vendée",
  # Le redécoupage CANTONAL porté par la loi du 21 juillet 1824 (Mothe-Achard,
  # Moutiers-les-Mauxfaits, Sainte-Hermine) n'est pas traité : il suppose une
  # trame cantonale antérieure à 1870, que la base n'a pas. La période
  # 1820-1831 est donc posée sur les cantons de 1876 — limite connue.
  "periodes": [
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["La Roche-sur-Yon-1", "La Roche-sur-Yon-2"],
              "moins": ["Rocheservière", "Le Poiré-sur-Vie"]},
        "2": {"reprend": ["Fontenay-le-Comte-1", "Fontenay-le-Comte-2"]},
        "3": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1869, "base": "1869", "deplacer": [
        (["Sainte-Hermine"], "1")]},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Chaillé-les-Marais", "Luçon", "Mareuil",
                          "Sainte-Hermine", "L'Hermenault"]},
        "2": {"cantons": ["La Châtaigneraie", "Saint-Hilaire-des-Loges",
                          "Fontenay-le-Comte", "Maillezais"]},
        "3": {"cantons": ["Le Poiré-sur-Vie", "Les Essarts",
                          "La Roche-sur-Yon", "Chantonnay"]},
        "4": {"cantons": ["Rocheservière", "Montaigu", "Saint-Fulgent",
                          "Mortagne", "Les Herbiers", "Pouzauges"]},
        "5": {"reste": True}}},
    # L'atlas écrit « par rapport à 1869 » mais cite les 3e, 4e et 5e
    # circonscriptions : 1869 n'en a que trois. La base ne peut être que 1831,
    # qui en a cinq. INTERPRÉTATION, comme pour le Tarn.
    {"depuis": 1820, "jusqu": 1831, "base": "1831", "circos": {
        "1": {"reprend": ["3", "4"]},
        "2": {"reprend": ["1", "2"]},
        "3": {"reprend": ["5"]}}},
    {"depuis": 1815, "jusqu": 1820, "base": "1869", "circos": {
        "Les Sables-d'Olonne": {"reprend": ["3"]},
        "Fontenay-le-Comte": {"reprend": ["2"], "plus": ["Chantonnay",
                                                          "Pouzauges"]},
        "Napoléon": {"reste": True}}},
  ]},

}


# Les autres départements, lus sur les cartes photographiées (4 octobre 2026).
sys.path.insert(0, str(Path(__file__).resolve().parent))
from regles_1815_1870 import REGLES_1815_1870  # noqa: E402
REGLES.update(REGLES_1815_1870)


def composition_1876(dep, date=None):
    """{canton (nom) -> circonscription (nom)} au segment 1876.

    `date` : date de lecture des cantons vivants, REF_DATE par défaut. La
    Meurthe (code 99) n'existe plus en 1878 : on la lit en 1870, où elle n'a
    pas de circonscription (scrutin de liste) — le découpage de base est
    alors VIDE, et ses règles n'emploient que des listes de cantons.
    """
    date = date or REF_DATE
    circos = {r["unit_id"]: r for r in csv.DictReader(
        (B / "unit_circo.csv").open(encoding="utf-8")) if r["dep"] == dep}
    # RÉPARATION : unit_canton.csv porte quatre noms abîmés, une lettre
    # accentuée remplacée par deux « \ufffd » en amont : Saint-Étienne-Nord-
    # et -Sud-Ouest (4221, 4222), Orléans-Est et -Ouest (4521, 4522). On la
    # rétablit ici — « É » en tête de mot, « é » ailleurs ; la source reste
    # à corriger.
    def _repare(nom):
        return re.sub(r"(^|(?<=[-\s]))\ufffd\ufffd", "É",
                      nom).replace("\ufffd\ufffd", "é")
    cantons = {r["unit_id"]: _repare(r["nom"])
               for r in csv.DictReader(
        (B / "unit_canton.csv").open(encoding="utf-8")) if r["dep"] == dep}

    def actifs(fichier, garde):
        d = {}
        for r in csv.DictReader((B / fichier).open(encoding="utf-8")):
            if r["valid_from"] <= date < r["valid_to"] and garde(r["unit_id"]):
                d[r["atom_id"]] = r["unit_id"]
        return d

    a_cant = actifs("membership_canton.csv", lambda u: u in cantons)
    a_circ = actifs("membership_circo.csv",
                    lambda u: u in circos and circos[u]["segment_depuis"] == "1876")

    # LES CANTONS VIVANTS À LA DATE, et non toute la nomenclature.
    #
    # `unit_canton.csv` couvre 1870-2012 : la Haute-Vienne y compte 29 cantons,
    # dont Limoges-Est et Limoges-Ouest qui n'ont AUCUN atome en 1878 — ils
    # seront créés plus tard. Contrôler la partition contre la nomenclature
    # entière rendait donc « partition rompue » sur les six périodes du
    # département, pour un défaut qui n'existait pas.
    #
    # *Le référentiel d'une partition doit être daté comme le reste.*
    vivants = {cantons[ct] for ct in a_cant.values()}

    lien = collections.defaultdict(collections.Counter)
    for atome, ct in a_cant.items():
        if atome in a_circ:
            lien[cantons[ct]][circos[a_circ[atome]]["nom"]] += 1
    # Un canton peut déborder si une commune est mal rattachée : on retient la
    # circonscription majoritaire ET l'on signale le partage.
    out, partages = {}, []
    for ct, c in lien.items():
        out[ct] = c.most_common(1)[0][0]
        if len(c) > 1:
            partages.append((ct, dict(c)))
    return out, partages, vivants


def applique(dep, periode, connus, univers=None):
    """Enveloppe : retire les cantons `absents` de la période.

    `absents` : cantons qui, à cette date, n'appartiennent pas au
    département — Montbéliard et Audincourt, encore haut-saônois en 1815 et
    rattachés au Doubs en 1816. Ils ne reçoivent rien, et la partition est
    contrôlée sans eux.
    """
    absents = set(periode.get("absents", ()))
    univ = set(univers or ()) - absents
    res = _applique(dep, periode, connus, univ)
    return {ct: c for ct, c in res.items() if ct not in absents}


def _applique(dep, periode, connus, univers=None):
    """Calcule {canton -> circo} d'une période à partir de son découpage de base.

    `univers` : les cantons VIVANTS à la date, qui peuvent être plus nombreux
    que ceux du découpage de base. C'est le cas quand la couche circo de 1876
    laisse un canton sans circonscription — Avignon-Sud, Le Havre-Sud, les six
    cantons de Rouen : leur unique atome est une FRACTION cantonale de la ville,
    et la couche ne rattache aucune fraction.

    Faire porter le « reste » sur les seuls cantons de la base reviendrait à
    propager ce trou dans toutes les périodes reconstruites.
    *Le référentiel d'une partition doit être les cantons vivants, pas ceux que
    la couche de départ a bien voulu couvrir.*
    """
    base = connus[periode["base"]]
    tous = set(base) | set(univers or ())
    res = {}

    if periode.get("copie"):
        return dict(base)

    if "fusionner" in periode:
        res = dict(base)
        for sources, cible in periode["fusionner"]:
            for ct, c in list(res.items()):
                if c in sources:
                    res[ct] = cible

    if "renommer" in periode:
        res = res or dict(base)
        res = {ct: periode["renommer"].get(c, c) for ct, c in res.items()}

    if "circos" in periode:
        pris, reste_pour = set(), None
        for num, r in periode["circos"].items():
            if r.get("reste"):
                reste_pour = num
                continue
            cts = set(r.get("cantons", []))
            for src in r.get("reprend", []):
                cts |= {ct for ct, c in base.items() if c == src}
            cts |= set(r.get("plus", []))
            cts -= set(r.get("moins", []))
            for ct in cts:
                res[ct] = num
            pris |= cts
        if reste_pour:
            for ct in tous - pris:
                res[ct] = reste_pour
        else:
            # AUCUN « reste » DÉCLARÉ, et des cantons non attribués.
            #
            # Cas des Vosges 1824-1828 : l'atlas dit ce que deviennent les 1re,
            # 2e, 4e et 5e circonscriptions de 1831, et ne dit RIEN de la 3e.
            # La lecture conservatrice est que ce qui n'est pas mentionné ne
            # change pas — on reconduit donc la circonscription de base.
            #
            # C'est une INTERPRÉTATION, et elle est signalée comme telle à
            # chaque exécution. L'autre lecture — un oubli dans la
            # transcription — ne se départage que sur l'original.
            orphelins = tous - pris
            for ct in orphelins:
                res[ct] = base[ct]
            if orphelins:
                periode.setdefault("_reconduits", sorted(orphelins))

    if "deplacer" in periode:
        res = res or dict(base)
        for cts, vers in periode["deplacer"]:
            for ct in cts:
                res[ct] = vers

    return res


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dep", action="append")
    ap.add_argument("--csv", action="store_true",
                    help="écrire circo/composition_1815_1870.csv")
    args = ap.parse_args()
    sortie = []
    deps = args.dep or sorted(REGLES)

    total_ok = True
    for dep in deps:
        R = REGLES[dep]
        base76, partages, tous_cantons = composition_1876(dep, R.get("date"))
        # Saales et Schirmeck existent avant 1871 et sont cités par les règles,
        # mais n'ont plus d'atome français en 1878 : l'annexion les a retirés.
        # Ils appartiennent donc au référentiel des périodes anciennes.
        cites = set()
        for per in REGLES[dep]["periodes"]:
            for r in per.get("circos", {}).values():
                cites |= set(r.get("plus", [])) | set(r.get("cantons", []))
            for cts, _ in per.get("deplacer", []):
                cites |= set(cts)
        hors_1876 = cites - tous_cantons
        if hors_1876:
            print(f"  cantons cités par l'atlas mais absents de 1876 "
                  f"(annexion de 1871) : {sorted(hors_1876)}")
            tous_cantons = tous_cantons | hors_1876
        print(f"\n{'='*66}\n{dep} {R['nom']} — {len(tous_cantons)} cantons\n{'='*66}")
        print(f"1876 : {len(base76)} cantons rattachés, "
              f"{len(set(base76.values()))} circonscriptions")
        if partages:
            print(f"  ATTENTION — {len(partages)} cantons à cheval sur "
                  f"plusieurs circos en 1876 :")
            for ct, c in partages[:5]:
                print(f"     {ct} : {c}")
        manque = tous_cantons - set(base76)
        if manque:
            print(f"  cantons sans circo en 1876 : {sorted(manque)}")

        # RÉSOLUTION PAR ITÉRATION, et non dans l'ordre de saisie.
        #
        # Les règles se citent en avant comme en arrière : la Yonne fait
        # dépendre 1831-1848 de 1815, déclaré plus bas. Imposer un ordre de
        # saisie reporterait sur la transcription une contrainte que le
        # programme sait résoudre — et une transcription qu'il faut ordonner
        # est une transcription qu'on finit par mal ordonner.
        connus = {"1876": base76}
        restantes = list(R["periodes"])
        ordonnees = []
        while restantes:
            faisables = [p for p in restantes if p["base"] in connus]
            if not faisables:
                for p in restantes:
                    print(f"  {p['depuis']}-{p['jusqu']} : base « {p['base']} » "
                          f"introuvable — dépendance circulaire ou base absente.")
                total_ok = False
                break
            for p in faisables:
                connus[str(p["depuis"])] = applique(dep, p, connus,
                                                    tous_cantons)
                ordonnees.append(p)
                restantes.remove(p)

        for p in sorted(ordonnees, key=lambda x: -x["depuis"]):
            res = connus[str(p["depuis"])]
            n_circo = len(set(res.values()))
            oublies = tous_cantons - set(p.get("absents", ())) - set(res)
            doubles = [ct for ct in res if ct not in tous_cantons]
            ok = not oublies and not doubles
            total_ok &= ok
            etat = "partition complète" if ok else "PARTITION ROMPUE"
            print(f"\n  {p['depuis']}-{p['jusqu']} (base {p['base']}) : "
                  f"{n_circo} circos, {len(res)} cantons — {etat}")
            if oublies:
                print(f"     cantons non attribués : {sorted(oublies)}")
            if doubles:
                print(f"     cantons inconnus du département : {sorted(doubles)}")
            if p.get("_reconduits"):
                print(f"     INTERPRÉTATION — {len(p['_reconduits'])} cantons non"
                      f" mentionnés par l'atlas, reconduits depuis {p['base']} :")
                print(f"        {', '.join(p['_reconduits'])}")
                print(f"        (leur circonscription : "
                      f"{sorted({connus[p['base']][c] for c in p['_reconduits']})})")
            for ct, c in sorted(res.items()):
                sortie.append({"dep": dep, "departement": R["nom"],
                               "depuis": p["depuis"], "jusqu": p["jusqu"],
                               "base": p["base"], "circonscription": c,
                               "canton": ct,
                               "interprete": "oui" if ct in (p.get("_reconduits") or [])
                                             else ""})
            g = collections.defaultdict(list)
            for ct, c in res.items():
                g[c].append(ct)
            for c in sorted(g):
                print(f"     [{c}] {len(g[c])} cantons : "
                      f"{', '.join(sorted(g[c]))[:88]}")

    if args.csv:
        import csv as _csv
        f = RACINE / "circo" / "composition_1815_1870.csv"
        champs = ["dep", "departement", "depuis", "jusqu", "base",
                  "circonscription", "canton", "interprete"]
        with f.open("w", newline="", encoding="utf-8") as fh:
            w = _csv.DictWriter(fh, fieldnames=champs)
            w.writeheader()
            w.writerows(sorted(sortie, key=lambda x: (x["dep"], -x["depuis"],
                                                      x["circonscription"], x["canton"])))
        print(f"\n{f.name} écrit — {len(sortie)} lignes "
              f"(canton × période × département).")

    print(f"\n{'='*66}")
    print(f"Toutes les partitions sont complètes : {total_ok}")
    print("\nRAPPEL : une partition valide ne prouve pas l'exactitude — une")
    print("permutation de deux circonscriptions passerait au travers. C'est un")
    print("filet contre les fautes de saisie, pas un contrôle de la source.")
    return 0 if total_ok else 1


if __name__ == "__main__":
    sys.exit(main())
