"""outils/noms.py — la clé de rapprochement des noms

    from outils.noms import cle
    cle("Saint-Merri")          # 'saintmerri'

Tirée de `circo/extrait_paris.py`, le 26 octobre 2026. Elle y était écrite pour
les quartiers de Paris, et `cog1968/` l'empruntait pour les communes de 1968 :
l'importer de là imposait `openpyxl` à des scripts qui ne lisent aucun xlsx.
La table des coquilles reste celle des quartiers ; elle ne touche aucun nom de
commune connu, mais elle s'applique à tous.
"""
import unicodedata

# Coquilles de saisie. Chacune est justifiée par une preuve INTERNE : les deux
# formes coexistent dans le fichier et désignent le même quartier. Aucune
# n'est corrigée de mémoire — le nom canonique viendra de la jointure avec la
# couche officielle. Ici on ne fait que réunir ce qui est déjà réuni ailleurs.
# Noter que la coquille est souvent PLUS fréquente que la forme correcte :
# la fréquence ne décide de rien.
COQUILLES = {
    "artetmetiers": "artsetmetiers",
    "chaussedantin": "chausseedantin",
    "enfantrouges": "enfantsrouges",
    "faubourgmontmarte": "faubourgmontmartre",
    "lavilette": "lavillette",
    "maisonsblanche": "maisonblanche",
    "marche": "marches",
    "montmarte": "montmartre",
    "portesaintdenis": "portedesaintdenis",
    "rochechouar": "rochechouart",
    "saintaveye": "saintavoye",
    "saintmarguerite": "saintemarguerite",
}


def cle(nom):
    """Clé de rapprochement : sans accent, sans tiret, sans espace."""
    n = unicodedata.normalize("NFD", nom.lower())
    n = "".join(c for c in n if unicodedata.category(c) != "Mn")
    n = "".join(c for c in n if c.isalnum())
    return COQUILLES.get(n, n)
