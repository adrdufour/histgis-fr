"""outils/base.py — se connecter à la base histgis depuis Python

    from outils.base import connexion
    cx = connexion()

Tirée de `circo/paris_quartiers.py`, le 26 octobre 2026, où les scripts Paris
et `cog1968/rappel_1968.py` allaient la chercher. `cantons/consolide_registre.py`
et `cantons/verif_annexe_vii.py` en avaient chacun une copie, restée sur
`dbname=histgis` écrit en dur : ils lisaient la base de production même quand
`PGDATABASE` désignait la copie en construction.
"""
import os

import psycopg2

# Le nom de la base vient de `PGDATABASE`, comme pour `psql` et `ogr2ogr` —
# ajouté le 6 septembre 2026, en essayant la chaîne sur `histgis_essai`.
#
# Il était écrit en dur dans les trois candidats, et les quatre scripts Paris
# partageaient cette fonction : `rejouer_apres_rebuild.sh` construisait la copie
# pendant qu'ils écrivaient dans la base de PRODUCTION, sans que rien n'échoue.
#
# Ce que la liste de candidats existe pour faire, et qu'il ne faut pas défaire :
# `psql` et `ogr2ogr` sont les binaires du système, dont libpq cherche la socket
# dans `/var/run/postgresql` ; `psycopg2` vient de l'environnement conda, dont
# libpq la cherche dans `/tmp`. **Le même `dbname=` ne désigne donc pas le même
# serveur selon qui l'interprète.** Passer un DSN unique depuis le shell — le
# premier correctif tenté — fait échouer le Python sur
# « socket /tmp/.s.PGSQL.5432 » alors que le shell vient de se connecter sans
# peine. Seul le nom de la base est paramétré ; le chemin de la socket reste
# cherché, parce que c'est lui qui diffère d'un client à l'autre.
_BASE = os.environ.get("PGDATABASE", "histgis")

DSN_CANDIDATS = [
    f"dbname={_BASE} host=/var/run/postgresql",
    f"dbname={_BASE}",
    f"dbname={_BASE} host=localhost",
]


def connexion():
    # `HISTGIS_DSN` reste l'échappatoire explicite, et il n'a PAS de repli :
    # une connexion nommée à la main qui échoue doit le dire, pas se rabattre
    # en silence sur une autre base.
    if os.environ.get("HISTGIS_DSN"):
        return psycopg2.connect(os.environ["HISTGIS_DSN"])
    for dsn in DSN_CANDIDATS:
        try:
            return psycopg2.connect(dsn)
        except psycopg2.OperationalError:
            pass
    raise SystemExit(
        f"Connexion impossible à « {_BASE} ». Essayés : "
        + " | ".join(DSN_CANDIDATS)
        + "\nDéfinir HISTGIS_DSN, ou PGDATABASE pour changer de base.")
