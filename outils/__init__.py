"""outils — le code que plusieurs dossiers du dépôt partagent.

    import sys
    sys.path.insert(0, str(RACINE))
    from outils.base import connexion
    from outils.noms import cle

Réuni le 26 octobre 2026. Avant, `connexion()` était recopiée dans trois
scripts (deux d'entre elles ignoraient `PGDATABASE`), et quatre scripts de
`cog1968/` importaient `cle()` de `circo/extrait_paris.py` — ce qui leur
imposait `openpyxl` pour une fonction de cinq lignes.
"""
