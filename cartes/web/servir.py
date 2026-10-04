#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
servir.py — sert `cartes/web/` en local et ouvre la page.

    python3 cartes/web/servir.py            # port 8765
    python3 cartes/web/servir.py 9000       # autre port
    python3 cartes/web/servir.py --sans-navigateur

Pourquoi un serveur plutôt qu'un double-clic
--------------------------------------------
La page charge ses données par `fetch()`. Les navigateurs traitent chaque
fichier ouvert en `file://` comme une origine distincte et refusent la requête :
on obtient une page blanche et une erreur CORS, pas un message utile. Un
serveur local supprime le problème sans rien installer.

Les fichiers exportés sont gros et se répètent d'une année à l'autre : le
serveur les compresse à la volée, ce que `http.server` ne fait pas. Sur un
département entier cela divise le transfert par cinq à dix — c'est du JSON,
donc très redondant.
"""

import argparse
import gzip
import io
import os
import socketserver
import sys
import threading
import webbrowser
from http.server import SimpleHTTPRequestHandler
from pathlib import Path

RACINE = Path(__file__).resolve().parent


class Gestionnaire(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=str(RACINE), **kw)

    def end_headers(self):
        # Deux régimes de cache, et les confondre coûte cher.
        #
        # Les fichiers de CONFIGURATION — `c_<sig>.json`, `x_<sig>.json` — sont
        # adressés par leur contenu : leur nom EST le md5 de la composition.
        # Un contenu différent porte forcément un autre nom, donc on peut les
        # garder indéfiniment.
        #
        # Les autres — `index.json`, `communes.json`, `contours.json`,
        # `index.html` — gardent le MÊME nom d'un export à l'autre. Les mettre
        # en cache une heure fige l'aiguillage : la page continue de servir
        # l'ancien index, donc les anciennes configurations, alors que le
        # disque est à jour. C'est ce qui a fait croire pendant une soirée du
        # 20 août 2026 que Bihorel manquait dans la base — la base était juste,
        # l'export était juste, seul le navigateur était en retard. Et comme
        # `annee_ref` ne change pas d'un export à l'autre, l'ancien fichier se
        # présentait sous une identité crédible : rien ne trahissait la
        # péremption.
        #
        # Règle : ne mettre en cache que ce dont le nom garantit le contenu.
        nom = os.path.basename(self.path.split("?", 1)[0])
        if nom.startswith(("c_", "x_")) and nom.endswith(".json"):
            self.send_header("Cache-Control", "public, max-age=31536000, immutable")
        else:
            self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def send_head(self):
        chemin = self.translate_path(self.path)
        if not (chemin.endswith(".json") and os.path.isfile(chemin)):
            return super().send_head()
        accepte = self.headers.get("Accept-Encoding", "")
        brut = open(chemin, "rb").read()
        if "gzip" in accepte:
            corps = gzip.compress(brut, 6)
            encodage = "gzip"
        else:
            corps, encodage = brut, None
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(corps)))
        if encodage:
            self.send_header("Content-Encoding", encodage)
        self.end_headers()
        return io.BytesIO(corps)

    def log_message(self, fmt, *args):
        if "404" in (fmt % args):
            sys.stderr.write("  manquant : %s\n" % self.path)


class Serveur(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("port", nargs="?", type=int, default=8765)
    ap.add_argument("--sans-navigateur", action="store_true")
    args = ap.parse_args()

    if not (RACINE / "donnees" / "index.json").exists():
        print("Les données ne sont pas exportées.", file=sys.stderr)
        print("Lancer d'abord :  python3 cartes/export_web.py", file=sys.stderr)
        sys.exit(1)

    url = f"http://127.0.0.1:{args.port}/index.html"
    with Serveur(("127.0.0.1", args.port), Gestionnaire) as srv:
        print(f"Page servie sur {url}")
        print("Ctrl-C pour arrêter.")
        if not args.sans_navigateur:
            threading.Timer(0.6, lambda: webbrowser.open(url)).start()
        try:
            srv.serve_forever()
        except KeyboardInterrupt:
            print("\nArrêté.")


if __name__ == "__main__":
    main()
