#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
servir.py — sert `cartes/web/` en local et ouvre la page.

    python3 cartes/web/servir.py            # port 8765
    python3 cartes/web/servir.py 9000       # autre port
    python3 cartes/web/servir.py --sans-navigateur

Il sert aussi les routes du dépôt sur Wikimedia Commons (`/commons/…`,
voir `commons.py` et LISEZMOI.md), actives seulement si `commons.toml` existe.

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
import json
import os
import socketserver
import sys
import threading
import webbrowser
from http.server import SimpleHTTPRequestHandler
from pathlib import Path

RACINE = Path(__file__).resolve().parent
sys.path.insert(0, str(RACINE))
from commons import Commons, ErreurCommons  # noqa: E402

COMMONS = Commons(RACINE / "commons.toml")
# Une carte de département avec ses communes pèse quelques mégaoctets ; au-delà
# de 60 Mo c'est une erreur, pas une carte.
CORPS_MAX = 60 * 1024 * 1024


class Gestionnaire(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=str(RACINE), **kw)

    def send_response(self, code, message=None):
        self._code = code
        super().send_response(code, message)

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
        #
        # Et seulement s'il a été TROUVÉ. Le nom garantit le contenu, pas sa
        # présence : le 23 octobre 2026, un 404 servi pendant un export de
        # l'Aisne (qui vide `dep/02/` avant de le réécrire) est parti avec
        # « immutable, un an », et le navigateur a refusé 1870 même après
        # rechargement, alors que le fichier était revenu sur le disque.
        nom = os.path.basename(self.path.split("?", 1)[0])
        if (nom.startswith(("c_", "x_")) and nom.endswith(".json")
                and getattr(self, "_code", 200) == 200):
            self.send_header("Cache-Control", "public, max-age=31536000, immutable")
        else:
            self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    # ------------------------------------------------------------------
    # Routes Commons
    #
    # Le serveur détient un jeton qui peut déposer des fichiers sous le nom de
    # son propriétaire. N'importe quelle page ouverte dans le même navigateur
    # peut envoyer un POST vers 127.0.0.1 : sans garde, un site tiers pourrait
    # déposer sur Commons à sa place. Deux gardes, chacune suffisante :
    #   * `Content-Type: application/json` obligatoire — un formulaire ou un
    #     fetch « simple » d'une autre origine ne peut pas le poser sans
    #     requête préalable CORS, à laquelle ce serveur ne répond pas ;
    #   * l'en-tête `Origin`, s'il est présent, doit être celui de la page.
    # ------------------------------------------------------------------
    def _origine_ok(self):
        o = self.headers.get("Origin")
        if not o:
            return True
        hote = self.headers.get("Host", "")
        return o in (f"http://{hote}", f"https://{hote}")

    def _json(self, code, obj):
        corps = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(corps)))
        self.end_headers()
        self.wfile.write(corps)

    def do_GET(self):
        if self.path.split("?", 1)[0] == "/commons/etat":
            if not self._origine_ok():
                return self._json(403, {"erreur": "origine refusée"})
            COMMONS.recharge()          # le fichier a pu être créé entre-temps
            try:
                return self._json(200, COMMONS.etat())
            except ErreurCommons as e:
                return self._json(502, {"erreur": str(e)})
        return super().do_GET()

    def do_POST(self):
        route = self.path.split("?", 1)[0]
        if route not in ("/commons/verifier", "/commons/envoi", "/commons/wikipedia"):
            return self._json(404, {"erreur": "route inconnue"})
        if not self._origine_ok():
            return self._json(403, {"erreur": "origine refusée"})
        if not self.headers.get("Content-Type", "").startswith("application/json"):
            return self._json(415, {"erreur": "JSON attendu"})
        n = int(self.headers.get("Content-Length") or 0)
        if n > CORPS_MAX:
            return self._json(413, {"erreur": "fichier trop gros"})
        try:
            q = json.loads(self.rfile.read(n).decode("utf-8"))
        except ValueError:
            return self._json(400, {"erreur": "JSON illisible"})
        try:
            if route == "/commons/wikipedia":
                titres = q.get("titres", [])
                if not isinstance(titres, list):
                    return self._json(400, {"erreur": "titres : liste attendue"})
                return self._json(200, {"titres": COMMONS.verifie_wikipedia(titres)})
            if route == "/commons/verifier":
                return self._json(200, COMMONS.verifie(
                    q.get("fichier", ""), q.get("categories", [])))
            nom, svg, texte = q.get("nom"), q.get("svg"), q.get("texte")
            if not (nom and svg and texte):
                return self._json(400, {"erreur": "nom, svg et texte requis"})
            if not nom.lower().endswith(".svg"):
                return self._json(400, {"erreur": "le nom doit finir par .svg"})
            return self._json(200, COMMONS.depose(
                nom, svg.encode("utf-8"), texte, bool(q.get("ignorer"))))
        except ErreurCommons as e:
            return self._json(502, {"erreur": str(e)})

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
